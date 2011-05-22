' it will create new editor window, copy all text from first window into new
' and save new file as C:\SAMPLE.TXT
const module_name  = "xxxx"         'this name must be unique !!!
const module_desc  = "some name"  'script description
const module_ver   = "1.0"         'version

sub Main      'main procedure

end sub


' name "Init" is required, its called automatically during initialization to create menu items
' addMenuItem "Name of menu item", "Name of submenu if required", "Main"
sub Init
  addMenuItem "Name of menu item", "", "Main"
end sub
