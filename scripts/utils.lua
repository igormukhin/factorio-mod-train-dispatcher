function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end