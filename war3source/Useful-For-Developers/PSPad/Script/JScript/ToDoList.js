/**
 *  PSPad Todo script
 *  (c) by Carney
 *
 */

var module_name = "TodoListJS";
var module_ver = "0.09";

function openScript() {
  var obj1 = newEditor();
  obj1.openFile(moduleFileName("TodoListJS"));
}


var fs = new ActiveXObject("Scripting.FileSystemObject")

function findTodos(filename) {
  var txt = "";
  var r, re, line;
  var i = 0
  var fr;

  re = new RegExp("TODO:");
  fr = fs.GetFile(filename).OpenAsTextStream(1, 0);

  while (!fr.AtEndOfStream) {
    line = fr.ReadLine();
    i++;
    r = line.search(re);
    if (r != -1) {
      txt = txt.concat(filename + ": "+ i +": " + line.substr(r) + "\n");
    }
  }
  fr.Close( );

  return txt;
}

function todoList() {
  var data = "";
  var fr;
  var obj1 = NewEditor(); //New editor object
  var i = 0;

  for (i = 0; i < (projectFilesCount()-1); i++) {
    fr = projectFiles(i);
    if (fs.FileExists(fr)) {
      data = data.concat(findTodos(fr));
//      echo(data);
    }
//    echo(ddd);
  }

 logClear();         // clearing log window
 logAddLine(data);   // printing the result to the log
}



function Init(){
  addMenuItem("View todos", "Todo list", "todoList");
  addMenuItem("View script", "Todo list", "openScript");
}
