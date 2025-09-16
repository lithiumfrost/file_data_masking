import os, malebolgia, strutils, times, cpuinfo

## Sanitized PDF Directory Duplicator
##
## Recursively duplicates a directory tree, creating empty directories and replacing each file with a sanitized PDF containing the original filename.
## Runs in parallel for speed. Intended for testing or sharing metadata without exposing sensitive file contents.

const helpText = """
Sanitized PDF Directory Duplicator

Usage:
  ./mask_files <source_folder> <destination_folder>

Description:
  Recursively duplicates a directory tree, creating empty directories and replacing each file with a sanitized PDF containing the original filename. Runs in parallel for speed.

Options:
  -h, --help    Show this help message and exit.
"""

## Generate minimal PDF content with text.
## Escapes parentheses and backslashes to ensure valid PDF.
## text: the string to display in the PDF
proc generatePdfContent*(text: string): string =
  let escapedText = text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
  let streamContent = "BT\n/F1 12 Tf\n100 700 Td\n(" & escapedText & ") Tj\nET"
  let streamLength = streamContent.len

  let obj1 = "1 0 obj\n<< /Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
  let obj2 = "2 0 obj\n<< /Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n"
  let obj3 = "3 0 obj\n<< /Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n/Resources << /Font << /F1 5 0 R >> >>\n>>\nendobj\n"
  let obj4 = "4 0 obj\n<< /Length " & $streamLength & " >>\nstream\n" & streamContent & "\nendstream\nendobj\n"
  let obj5 = "5 0 obj\n<< /Type /Font\n/Subtype /Type1\n/BaseFont /Helvetica\n>>\nendobj\n"

  let PdfHeader = "%PDF-1.4\n"
  let PdfFooter = "%%EOF\n"
  let parts = [PdfHeader, obj1, obj2, obj3, obj4, obj5]
  var offsets: array[6, int]
  var currentOffset = 0
  for i, part in parts:
    offsets[i] = currentOffset
    currentOffset += part.len

  let xrefStart = currentOffset
  var xrefEntries = "0000000000 65535 f \n"
  for i in 1..5:
    let offset = offsets[i]
    xrefEntries.add(intToStr(offset, 10) & " 00000 n \n")

  let xref = "xref\n0 6\n" & xrefEntries
  let trailer = "trailer\n<< /Size 6\n/Root 1 0 R\n>>\nstartxref\n" & $xrefStart & "\n" & PdfFooter

  result = parts.join("") & xref & trailer

## Replace a file by a PDF stub with original file's name, preserving original file size via padding or truncation.
proc processFile*(srcPath, dstPath: string) =
  try:
    let fileSize = getFileSize(srcPath)
    let pdfText = "Sanitized file. Original: " & srcPath
    let pdfContent = generatePdfContent(pdfText)

    if pdfContent.len > fileSize:
      let truncated = pdfContent[0..<fileSize]
      writeFile(dstPath, truncated)
    else:
      let padding = fileSize - pdfContent.len
      let content = pdfContent & repeat('\0', padding)
      writeFile(dstPath, content)
  except CatchableError as e:
    echo "Error processing ", srcPath, ": ", e.msg

## Parallel recursive directory walk and sanitizing copy.
## Copies tree structure, replaces files with same-sized sanitized PDF stubs in parallel.
proc duplicateFolder*(srcDir, dstDir: string) =
  createDir(dstDir)
  let numWorkers = countProcessors()
  var m = createMaster()

  m.awaitAll:
    # First pass: Create all directories
    for path in walkDirRec(srcDir, yieldFilter = {pcDir}):
      let relPath = path.relativePath(srcDir)
      let dstPath = dstDir / relPath
      createDir(dstPath)

    # Second pass: Process files in parallel
    for path in walkDirRec(srcDir, yieldFilter = {pcFile}):
      let relPath = path.relativePath(srcDir)
      let dstPath = dstDir / relPath
      m.spawn processFile(path, dstPath)

if paramCount() != 2 or paramStr(1) in ["-h", "--help"]:
  echo helpText
  quit(0)

let srcDir = paramStr(1)
let dstDir = paramStr(2)

if not dirExists(srcDir):
  echo "Source directory does not exist: ", srcDir
  quit(1)

let startTime = cpuTime()
duplicateFolder(srcDir, dstDir)
let endTime = cpuTime()
echo "Duplication completed in ", endTime - startTime, " seconds"
