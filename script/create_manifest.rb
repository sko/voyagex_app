# TODO: mobile and not mobile

if ARGV.length >= 1 && ARGV.include?('-m')
  v_x_css = ['application.mobile', 'main.mobile']
  v_x_js = ['preload.mobile', 'application.mobile', 'comm/application']
  cache_entry_file = 'app/views/main/cache_entries.mobile.txt'
else
  v_x_css = ['application', 'main']
  v_x_js = ['preload', 'application', 'comm/application']
  cache_entry_file = 'app/views/main/cache_entries.txt'
end

`rm #{cache_entry_file}`

# this is all media referenced in app-files
find_media_cmd = "grep -oR \"[^ '\\\"]\\\\+\\\\.\\\\(png\\\\|gif\\\\|jpe\\\\?g\\\\|mp3\\\\|mpeg\\\\)\" app/ | sed \"s/^.\\\\+://\" | sed \"s/^\\\/.\\\\+//\" | grep \"[a-zA-Z0-9]\" | sort"
#find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^.+\/{{name}}-[^-]+\.{{suffix}}\""
find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public\/assets\/{{name}}-[^-]+\.{{suffix}}\""
uniq_css_paths = []
uniq_js_paths = []
uniq_media_paths = []
#puts "find_media_cmd = #{find_media_cmd}"
# find voyagex assets
puts "# voyagex css and js assets"
`echo "# voyagex assets" >> #{cache_entry_file}`
v_x_css.each_with_index do |name, idx|
  suffix = 'css'
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  #puts "asset = #{asset}"
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_css_paths.include? uniq_path
    #puts "asset = #{asset}"
    #puts "uniq_path = #{uniq_path}"
    uniq_css_paths << uniq_path
    #puts "#{asset.gsub(/^public/, '').split.first.strip}"
    `echo "#{asset.gsub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.gsub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
v_x_js.each_with_index do |name, idx|
  suffix = 'js'
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  #puts "asset = #{asset}"
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_js_paths.include? uniq_path
    #puts "asset = #{asset}"
    #puts "uniq_path = #{uniq_path}"
    uniq_js_paths << uniq_path
    #puts "#{asset.gsub(/^public/, '').split.first.strip}"
    `echo "#{asset.gsub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.gsub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
if false
puts "# voyagex media assets"
# this is all media referenced in app-files
`#{find_media_cmd}`.split.each_with_index do |entry, idx|
  name = entry.sub(/\.[a-zA-Z]+$/, '') 
  suffix = entry.sub(/^.+\.([a-zA-Z]+)$/, '\\1')
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_media_paths.include? uniq_path
    #puts "uniq_path = #{uniq_path}"
    uniq_media_paths << uniq_path
    #puts "#{asset.sub(/^public/, '').split.first.strip}"
    `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.sub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
end
# find 3rd-party assets
#puts "# 3rd-party media assets"
#{}`echo "# 3rd-party assets" >> #{cache_entry_file}`
puts "# all media assets"
`echo "# all media assets" >> #{cache_entry_file}`
# find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.css\" | sort"
# `#{find_asset_cmd}`.split.each_with_index do |asset, idx|
#   uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
#   next if uniq_css_paths.include? uniq_path
#   #puts "uniq_path = #{uniq_path}"
#   uniq_css_paths << uniq_path
#   #puts "#{asset.sub(/^public/, '').split.first.strip}"
#   `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
# end
# find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.js\" | sort"
# `#{find_asset_cmd}`.split.each_with_index do |asset, idx|
#   uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
#   next if uniq_js_paths.include? uniq_path
#   #puts "uniq_path = #{uniq_path}"
#   uniq_js_paths << uniq_path
#   #puts "#{asset.sub(/^public/, '').split.first.strip}"
#   `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
# end
# only media from subdirectories - @see regexp
#find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.(png|gif|jpe?g|mp3|mpeg)\" | sort"
find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+\\.(png|gif|jpe?g|mp3|mpeg)\" | sort"
`#{find_asset_cmd}`.split.each_with_index do |asset, idx|
  #puts "#{asset.sub(/^public/, '').strip}"
  `echo "#{asset.sub(/^public/, '').strip}" >> #{cache_entry_file}`
end
