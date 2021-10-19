# https://docs.microsoft.com/en-us/dotnet/standard/base-types/composite-formatting
# { index[,alignment][:formatString] }
# index - Position in the following array
# Alignment - The optional alignment component is a signed integer indicating the preferred formatted field width.
# formatString - 
# escaping braces - Specify two opening braces ("{{") in the fixed text to display one opening brace ("{"), or two closing braces ("}}") to display one closing brace ("}").
#
# The type's parameterless ToString method, which either overrides Object.ToString() or inherits the behavior of its base class, is called.
Write-Host ("0x{0:X}" -f  [Int64]::MaxValue)
Write-Host ("{0:E}" -f  [Int64]::MaxValue)
Write-Host ("{0:N}" -f  [Int64]::MaxValue)
Write-Host ("{0:D4}" -f 1)
