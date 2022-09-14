`/pipeline` hosts MATLAB code used for producing and visualizing
the key results from the deep-meg project, which is the scientific project that
inspired the acquisition of this shared dataset.

## Directory structure

```
.pipeline/
|-- README.md
|-- audio
|-- meg                            | matlab scripts for preprocessing data 
|-- models
`-- utilities
```
## Dependencies

- [Fieldtrip](https://github.com/fieldtrip/fieldtrip/)
  - version [d073bb2](https://github.com/fieldtrip/fieldtrip/commit/d073bb2) used together with code from [v.1](https://github.com/KristijanArmeni/Deep-MEG/tree/v1.0.0/pipeline) of the code in this repository (used for preprocessing)
