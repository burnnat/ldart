LDart
=====

Run Dart scripts with a linked packages directory.

Under ideal circumstances, this script should not be needed. However, there are situations which require its use; for example, Chrome Dev Editor does not create symlinks for `packages` directories under `tool/` and `test/`, so attempting to run scripts in those directories directly from the command line will fail. Running through LDart, however, will properly link the packages directory on-the-fly.

To install:

    pub global activate --source git https://github.com/burnnat/ldart.git

To run:

    pub global run ldart tool/script.dart arg1 arg2

Or, after adding `~/.pub-cache/bin` to `PATH`:

    ldart tool/script.dart arg1 arg2
