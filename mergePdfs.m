function mergePdfs(fileNames, outputFile)
%MERGEPDFS Merges the pdf-Documents in the input cell array fileNames into one
% single pdf-Document with file name outputFile

arguments
    fileNames string
    outputFile string
end

memSet = org.apache.pdfbox.io.MemoryUsageSetting.setupMainMemoryOnly();
merger = org.apache.pdfbox.multipdf.PDFMergerUtility;
cellfun(@(f) merger.addSource(f), cellstr(fileNames))
merger.setDestinationFileName(outputFile)
merger.mergeDocuments(memSet)
