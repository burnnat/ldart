import 'dart:io';
import 'dart:isolate';
import 'dart:math';

void main(List<String> args) {
  File target = new File(args.first).absolute;

  Directory dir = target.parent;
  Directory root = findRoot(dir);

  if (root == null) {
    print('Unable to locate package root.');
    return;
  }

  File runner = createRunner(target);

  Link link = new Link('${dir.path}/packages');
  link.createSync('${root.path}/packages');

  ReceivePort port = new ReceivePort();

  Isolate
    .spawnUri(
      new Uri.file(runner.path),
      [],
      port.sendPort
      // Rather than manually creating symlinks, the idiomatic
      // approach would be to use the 'packageRoot' argument:
      // packageRoot: Uri.parse('${dir.path}/packages')
      // Unfortunately, not all platforms support this.
    )
    .then((_) => port.first)
    .then((bool success) {
      link.deleteSync();
      runner.deleteSync();
    });
}

Directory findRoot(Directory start) {
  Directory dir = start;
  Directory prev = null;

  do {
    if (new Directory('${dir.path}/packages').existsSync()) {
      return dir;
    }

    prev = dir;
    dir = dir.parent;
  }
  while (prev.path != dir.path);

  return null;
}

File createRunner(File target) {
  // Hacky, but since we're bootstrapping the packages directory,
  // we can't just load up the 'path' library to parse the filename.
  String targetName = target.path.split("/").last;
  String contents = """
import 'dart:isolate';
import '$targetName' as child;

typedef void Local(List<String> args);
typedef void Portable(List<String> args, Object port);

void main(List<String> args, SendPort port) {
  bool success = false;

  try {
    if (child.main is Portable) {
      // Child will manually handle notification of exit,
      // so we can forget about the specified port.
      SendPort p = port;
      port = null;
      child.main(args, p);
    }
    else if (child.main is Local) {
      child.main(args);
    }
    else {
      child.main();
    }

    success = true;
  }
  finally {
    if (port != null) {
      port.send(success);
    }
  }
}
  """;

  String suffix = new Random().nextInt(1 << 32).toString();
  File output = new File('${target.parent.path}/_runner${suffix}.dart');

  output.writeAsStringSync(contents);

  return output;
}