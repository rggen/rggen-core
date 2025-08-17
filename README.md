[![Gem Version](https://badge.fury.io/rb/rggen-core.svg)](https://badge.fury.io/rb/rggen-core)
[![CI](https://github.com/rggen/rggen-core/workflows/CI/badge.svg)](https://github.com/rggen/rggen-core/actions?query=workflow%3ACI)
[![Maintainability](https://qlty.sh/badges/40f53c48-7f4c-4094-9907-2736e69527b3/maintainability.svg)](https://qlty.sh/gh/rggen/projects/rggen-core)
[![codecov](https://codecov.io/gh/rggen/rggen-core/branch/master/graph/badge.svg)](https://codecov.io/gh/rggen/rggen-core)
[![Discord](https://img.shields.io/discord/1406572699467124806?style=flat&logo=discord)](https://discord.com/invite/KWya83ZZxr)

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

* [GitHub Issue Tracker](https://github.com/rggen/rggen/issues)
* [GitHub Discussions](https://github.com/rggen/rggen/discussions)
* [Discord](https://discord.com/invite/KWya83ZZxr)
* [Mailing List](https://groups.google.com/d/forum/rggen)
* [Mail](mailto:rggen@googlegroups.com)

## Copyright & License

Copyright &copy; 2017-2025 Taichi Ishitani. RgGen::Core is licensed under the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE](LICENSE) for futher details.

## Code of Conduct

Everyone interacting in the RgGen project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rggen/rggen-core/blob/master/CODE_OF_CONDUCT.md).
