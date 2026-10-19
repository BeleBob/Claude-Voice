"""Local filter for transcribed speech, so insults never leave this machine.

Obscene words are masked with *** by a word list. The masked phrase is then
scored by rubert-tiny-toxicity (ONNX, CPU); phrases scored as an insult are
dropped. The order matters: the model scores any swearing as an insult, but
after masking a friendly "Клод, ***, сколько времени?" scores close to zero.
"""

import math
import os
import re

MASK = "***"
LABELS = ("non-toxic", "insult", "obscenity", "threat", "dangerous")

# Matched against each lowercased word with ё replaced by е.
OBSCENE = re.compile(
    r"""
    ^(?:на|по|ни|не|до|за|от|вы|при|раз|рас|недо|пере|о|а|у|с)?ху[йеияю]  # not плохую
    | пизд
    | ^бля
    | ^(?:за|вы|до|по|на|у|от|раз|рас|при|про|пере|недо|долбо|въ|съ|объ|подъ|изъ|разъ|отъ)?еб
    | ^муд(?:ак|ач|ил|оз|охал)
    | ^пид(?:ор|ар|р)
    | ^педик(?!юр) | ^педераст
    | ^сук(?:а|и|у|е|ой|ин\w*)$ | ^суч(?:к|ар|ий|ья|ье|ьи)
    | ^г[ао]ндон | ^шлюх | ^залуп | ^мандавош | ^манд(?:а|ы|е|у|ой)$ | ^дроч
    | ^жид(?:ы|ов|у|ом|ам|ами|ах|ок|ка|ки|овск\w*|ят\w*)?$
    | ^чурк | ^хач(?:и|ей|у|ом|ам|ами|ах|ик\w*)?$ | ^хохл | ^хохол$ | ^пиндос
    | ^черномаз | ^ниггер | ^нигер(?:ы|ов|а|у|ом|ами)?$ | ^нигга
    | fuck | ^shit | bitch | ^cunt | ^asshol | ^motherf | ^whore | ^dickhead
    | ^nigg(?:er|a) | ^fag(?:got)?s?$
    | ^bly(?:a|at|ad) | pizd | ^suk(?:a|i)$ | ^nahu[iy] | ^hu[iy]$ | ^huy | ^eba[ln]
    """,
    re.VERBOSE,
)
WORD = re.compile(r"\w+")


def mask_obscene(text):
    def repl(m):
        word = m.group(0).lower().replace("ё", "е")
        return MASK if OBSCENE.search(word) else m.group(0)

    return WORD.sub(repl, text)


class SpeechFilter:
    def __init__(self, model_dir, labels=("insult",), threshold=0.5):
        # Imported here so claude-hear can still run without the filter.
        import numpy
        import onnxruntime
        from tokenizers import Tokenizer

        self._np = numpy
        self._tok = Tokenizer.from_file(os.path.join(model_dir, "tokenizer.json"))
        self._tok.enable_truncation(512)
        opts = onnxruntime.SessionOptions()
        opts.intra_op_num_threads = 1
        self._sess = onnxruntime.InferenceSession(
            os.path.join(model_dir, "model.onnx"), opts, providers=["CPUExecutionProvider"]
        )
        unknown = set(labels) - set(LABELS)
        if unknown:
            raise ValueError(f"unknown filter labels: {', '.join(sorted(unknown))}")
        self._labels = [LABELS.index(label) for label in labels]
        self._threshold = threshold

    def scores(self, text):
        enc = self._tok.encode(text)
        feed = {
            name: self._np.array([values], dtype=self._np.int64)
            for name, values in (
                ("input_ids", enc.ids),
                ("attention_mask", enc.attention_mask),
                ("token_type_ids", enc.type_ids),
            )
        }
        logits = self._sess.run(None, feed)[0][0]
        return {label: 1 / (1 + math.exp(-float(x))) for label, x in zip(LABELS, logits)}

    def check(self, text):
        """Return (text to keep, None) or (None, (label, score)) for a dropped phrase."""
        masked = mask_obscene(text)
        scores = self.scores(masked)
        for i in self._labels:
            label = LABELS[i]
            if scores[label] >= self._threshold:
                return None, (label, scores[label])
        return masked, None
