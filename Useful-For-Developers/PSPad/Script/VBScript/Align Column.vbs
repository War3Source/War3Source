'Author: gogogadgetscott
'Published: 12-30-2005 21:41
Const module_name  = "Align"
Const module_ver   = "2.00"   

Sub AlignCol
    Dim Columns(100)
    
    '// Get delimiter
    delimiter = InputBox("Enter delimiter.", module_name, ",")
    If delimiter = "" Then Exit Sub
    
    '// Get working text
    text = handleSelText("")

    '// Determine end-of-line
    EOL = ""
    If InStr(text, Chr(13)) Then
        EOL = EOL & Chr(13)
    End If
    If InStr(text, Chr(10)) Then
        EOL = EOL & Chr(10)
    End If

    '// Get lines
    lines = Split(text, EOL)
    
    '// Make delimiter regexp safe
    Set regReplace = New RegExp
    With regReplace
        .Global     = True
        .IgnoreCase = True
        .Pattern    = "([\$|\(|\)|\*|\+|\.|\[|\]|\?|\\|\^|\{|\}|\|])"
    End With
    safeDelimiter = regReplace.Replace(delimiter, "\$1")
    
    '// Setup regexp object
    Set regSearch = New RegExp
    With regSearch
        .Global     = True
        .IgnoreCase = True
        .Pattern    = "([^" & safeDelimiter & "]*)(\s*)" & safeDelimiter
    End With

    '// Get all column's max width
    For Each line in lines
        Set Matches = regSearch.Execute(line)
        '// Initialize column index
        Column = 0
        For Each Match in Matches
            length = len(Match.SubMatches(0))
            If length > Columns(Column) Then
                Columns(Column) = length
            End If 
            Column = Column + 1
        Next
    Next
    
    '// Initialize line index
    i = -1
    
    '// Added spacing
    For Each line in lines 
        Column = 0
        newLine = ""
        i = i + 1
        Set Matches = regSearch.Execute(line)
        
        '// Sum matches and remove from orignal line
        '// Match should catch everything before delimiter
        foundText = ""
        For Each Match in Matches
            foundText = foundText & Match.SubMatches(0) & Match.SubMatches(1) & delimiter
        Next
        extraText = Replace(line, foundText, "")

        For Each Match in Matches
            Spaces  = Columns(Column) - Len(Match.SubMatches(0))
            newLine = newLine & Match.SubMatches(0) & String(Spaces, " ") & delimiter
            Column  = Column + 1
        Next
        If newLine <> "" Then
            lines(i) = newLine & extraText
        End If
    Next
    
    '// Replace text
    text = Join(lines, EOL)
    handleSelText text
End Sub

'// @param string Text to replace selected text
Private Function handleSelText(text)
    On Error Resume Next
    Set editor = newEditor()
    editor.assignActiveEditor
    If text = "" Then
        '// Get selected text
        handleSelText = editor.selText
        If handleSelText = "" Then
            '// No text was select. Get all text and select it.
            handleSelText  = editor.Text
            editor.command "ecSelectAll"
        End If
    Else
        '// Set selected text
        editor.selText text
    End If
End Function

Sub Init
    addMenuItem "Align columns", "Format code", "AlignCol"
End Sub
