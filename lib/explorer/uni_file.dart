abstract class UniFile {
  /*定义常见的文件操作(只读)，如
  * read 获取全部内容
  * list
  * isDir
  * isFile
  * getPath
  * getName
  * getSize
  * getParent
  * */
}

class LocalFile extends UniFile{

}

class SftpFile extends UniFile{
  static SftpFile create(String host, int port, String user, String password, String path){

  }
}