extends RefCounted
# Save exact original PNG bytes rather than re-encoding user-authored art.
static func import_file(path: String) -> String:
    if path.get_extension().to_lower()!="png":return ""
    var img:=Image.new()
    if img.load(path)!=OK or img.get_width()!=64 or img.get_height()!=64:return ""
    if img.get_format()!=Image.FORMAT_RGBA8:img.convert(Image.FORMAT_RGBA8)
    if img.is_empty():return ""
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://exo_skins"))
    var digest: String=FileAccess.get_md5(path)
    if digest.length()!=32:return ""
    var dest: String="user://exo_skins/skin_%s.png" % digest
    if FileAccess.file_exists(dest):return dest
    if DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(dest))!=OK:return ""
    return dest

static func load_skin(path: String) -> Image:
    var image:=Image.new()
    if not path.begins_with("user://exo_skins/") or not path.ends_with(".png"):return null
    if image.load(path)!=OK or image.get_width()!=64 or image.get_height()!=64:return null
    return image
