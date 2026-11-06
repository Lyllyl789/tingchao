///|
extern "js" fn arguments() -> FixedArray[String] =
  #| () => process.argv.slice(2)

///|
// Host I/O is bounded and never returns a platform exception to the caller.
extern "js" fn read_request(name : String) -> FixedArray[String] =
  #| (name) => {
  #|   let fd;
  #|   try {
  #|     const fs = process.getBuiltinModule('node:fs');
  #|     if (!fs.lstatSync(name).isFile()) return ['error', 'input.file: expected a regular file'];
  #|     fd = fs.openSync(name, 'r');
  #|     const info = fs.fstatSync(fd);
  #|     if (!info.isFile() || info.size > 1048576) return ['error', 'input.size: expected a regular file of at most 1 MiB'];
  #|     const bytes = Buffer.alloc(info.size + 1);
  #|     const count = fs.readSync(fd, bytes, 0, bytes.length, 0);
  #|     if (count > info.size) return ['error', 'input.changed: file grew while being read'];
  #|     return ['ok', new TextDecoder('utf-8', {fatal: true}).decode(bytes.subarray(0, count))];
  #|   } catch (_) {
  #|     return ['error', 'input.read: could not read a valid UTF-8 request'];
  #|   } finally {
  #|     if (fd !== undefined) { try { process.getBuiltinModule('node:fs').closeSync(fd); } catch (_) {} }
  #|   }
  #| }

///|
extern "js" fn diagnostic(message : String) -> Unit =
  #| (message) => process.stderr.write(message + '\n')

///|
extern "js" fn exit(code : Int32) -> Unit =
  #| (code) => { process.exitCode = code; }
