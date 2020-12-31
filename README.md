[![Gem Version](https://badge.fury.io/rb/rggen-core.svg)](https://badge.fury.io/rb/rggen-core)
[![CI](https://github.com/rggen/rggen-core/workflows/CI/badge.svg)](https://github.com/rggen/rggen-core/actions?query=workflow%3ACI)
[![Maintainability](https://api.codeclimate.com/v1/badges/53c8e6654c2b5ecb9142/maintainability)](https://codeclimate.com/github/rggen/rggen-core/maintainability)
[![codecov](https://codecov.io/gh/rggen/rggen-core/branch/master/graph/badge.svg)](https://codecov.io/gh/rggen/rggen-core)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=rggen_rggen-core&metric=alert_status)](https://sonarcloud.io/dashboard?id=rggen_rggen-core)
[![Gitter](https://badges.gitter.im/rggen/rggen.svg)](https://gitter.im/rggen/rggen?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# RgGen::Core

RgGen::Core is a core library of RgGen tool and provides features listed below:

* Structure and APIs for defining properties, parsers and error checkers of configuration file and register map documents
* Basic loaders for configuration file and register map documents
    * Ruby with APIs for description
    * YAML
    * TOML
    * JSON
* Structure and APIs for defining output file writers
* Building RgGen tool up by linking defined above features
* The `rggen` executable command

## Installation

During RgGen installation, RgGen::Core will also be installed automatically.

```
$ gem install rggen
```

If you want to install RgGen::Core only, use the command below:

```
$ gem install rggen-core
```

## Contact

Feedbacks, bug reports, questions and etc. are wellcome! You can post them by using following ways:

* [GitHub Issue Tracker](https://github.com/rggen/rggen-core/issues)
* [Chat Room](https://gitter.im/rggen/rggen)
* [Mailing List](https://groups.google.com/d/forum/rggen)
* [Mail](mailto:rggen@googlegroups.com)

## Copyright & License

Copyright &copy; 2017-2021 Taichi Ishitani. RgGen::Core is licensed under the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE](LICENSE) for futher details.

## Code of Conduct

Everyone interacting in the RgGen project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rggen/rggen-core/blob/master/CODE_OF_CONDUCT.md).
