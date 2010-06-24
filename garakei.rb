def garakei (ua) 
  return true if /^(?:KDDI|UP.Browser\/.+?)-(.+?) / =~ ua
  return true if /^DoCoMo/ =~ ua
  return ture if %r{^emobile/|^Mozilla/5.0 \(H11T; like Gecko; OpenBrowser\) NetFront/3.4$|^Mozilla/4.0 \(compatible; MSIE 6.0; Windows CE; IEMobile 7.7\) S11HT$} =~ ua
  return ture if /^(?:SoftBank|Semulator)/ =~ ua
  return ture if /^(Vodafone|Vemulator)/ =~ ua
  return ture if /^(J-PHONE|J-EMULATOR)/ =~ ua
  return ture if /^Mozilla\/3.0\(WILLCOM/ =~ ua
  return ture if /^Mozilla\/3.0\(DDIPOCKET/ =~ ua
  false
end

