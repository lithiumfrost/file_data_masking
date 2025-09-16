import unittest, os, strutils
import mask_files

test "generatePdfContent generates valid PDF structure":
  let content = generatePdfContent("filename.txt")
  check content.startsWith("%PDF-1.4\n")
  check "/Type /Page" in content
  check content.endsWith("%%EOF\n")

test "processFile creates padded or truncated pdf":
  let tmpSrc = "test_src.tmp"
  let tmpDst = "test_dst.tmp"
  writeFile(tmpSrc, repeat('X', 50))
  processFile(tmpSrc, tmpDst)
  check fileExists(tmpDst)
  # Should be same size
  check getFileSize(tmpDst) == 50
  removeFile(tmpSrc)
  removeFile(tmpDst)

# Note: File/folder operations for duplicateFolder would require temp dirs and more setup.
