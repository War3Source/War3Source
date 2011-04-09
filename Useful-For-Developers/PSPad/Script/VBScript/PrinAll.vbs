' it will print all open files to printer
const module_name  = "PrintAll"         'this name must be unique !!!
const module_ver   = "0.001a"            'version

sub PrintAll
  set obj = NewEditor()
  for i = 0 to editorsCount - 1
      obj.assignEditorByIndex(i)
      if i = 0 then     'for first file we call printer settings dialog
         obj.printFile(True)
      else              'all other files will be printed to selected printer
         obj.printFile(False)
      end if
  next  
end sub

' name "Init" is required, its called automatically during initialization to create menu items
sub Init
  addMenuItem "&Print all files","", "PrintAll"
end sub
