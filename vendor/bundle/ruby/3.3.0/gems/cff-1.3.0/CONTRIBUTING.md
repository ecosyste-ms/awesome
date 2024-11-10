# Contributing to the Ruby CFF Library
## Introduction

**Thank you** for considering a contribution to the **Ruby CFF Library**!

If you intended to contribute to another part of the Citation File Format project, for example the Citation File Format specification itself, please contribute to the respective repository ([list of repositories in the `citation-file-format` GitHub organization](https://github.com/orgs/citation-file-format/repositories)).

**Please follow these guidelines.** Their purpose is to make both contributing and accepting contributions easier for all parties involved.

There are many ways to contribute, e.g.:

* Tell a friend or colleague about the Citation File Format and Ruby CFF, or tweet about it
* Write blog posts, tutorials, etc. about the Citation File Format and Ruby CFF
* Review the format and its schema and documentation
* Improve wording in any prose output, including the specifications
* Create a new, better version of the schema and specifications
* Improve automated tests, continuous integration, documentation, etc.

## Ground Rules

Your contribution to Ruby CFF is valued, and it should be an enjoyable experience. To ensure this there is the Ruby CFF
[Code of Conduct](https://github.com/citation-file-format/ruby-cff/blob/main/CODE_OF_CONDUCT.md) which you are required to follow.

Please always start any contribution that will change the contents of this repository from [an issue](https://github.com/citation-file-format/ruby-cff/issues). This may mean [creating a new issue](https://github.com/citation-file-format/ruby-cff/issues/new) if it's something that hasn't been requested so far. This way,

* you can make sure that you don't invest your valuable time in something that may not be merged; and
* we can make sure that your contribution is something that will improve Ruby CFF, is in scope, and aligns with the roadmap for the Ruby CFF and the Citation File Format.

## Your First Contribution

If you are unsure where to begin with your contribution to CFF, have a look at the [open issues in this repository](https://github.com/citation-file-format/ruby-cff/issues), and see if you can identify one that you would like to work on.

If you have never contributed to an open source project, you may find this tutorial helpful: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

## Getting started

This is the workflow for contributions to this repository:

1. Take note of the [code of conduct](https://github.com/citation-file-format/ruby-cff/blob/main/CODE_OF_CONDUCT.md)
1. [Create a new issue](https://github.com/citation-file-format/ruby-cff/issues/new) if needs be, and discuss the changes you want to make with the maintainers and community
1. Fork the repository
1. Create a branch in your fork of the repository
1. Make changes in the new branch in your fork
   * Please don't forget tests!
   * If you add any classes, modules, methods, attributes, or constants, please document them
1. Create a pull request
1. Address any comments that come up during review
1. If and when your pull request has been merged, you can delete your branch (or the whole forked repository)

This workflow is loosely based on GitHub flow, and you can find more information in the [GitHub flow documentation](https://docs.github.com/en/get-started/quickstart/github-flow).

### Working with tests and documentation

There is a comprehensive test suite for Ruby CFF, which also contains a collection of test `CITATION.cff` files - both valid and invalid. Please add tests (and new test `CITATION.cff` files if appropriate) for any new features you add, or bugs you squash. It is advised to run these tests locally on your computer prior to submitting a pull request. However, if that's not possible, you still can submit the pull request and later check the status of the tests for your pull request on GitHub.

To run the tests, assuming that you have all the dependencies installed, simply run:
```shell
$ rake
```

To rebuild the documentation, if you have added to it or changed it:
```shell
$ rake rdoc
```
Then load `html/index.html` into a Web browser and double check it.

## FAQ

- **These guidelines do not address aspect XYZ! What should I do now?**

Please [submit an issue](https://github.com/citation-file-format/ruby-cff/issues/new), asking for clarification of and/or an addition to the guidelines.
