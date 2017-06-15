template LoadSprite(string name, string path)
{
  const char[] LoadSprite =
    "Surface surface_" ~ name ~ " = Surface(\"" ~ path ~ "\");" ~
    "m_tex_" ~ name ~ " = Texture(surface_" ~ name ~ ");" ~
    "m_sprite_" ~ name ~ " = new Sprite(m_tex_" ~ name ~ ");";
}

template SpriteMembers(string name)
{
  const char[] SpriteMembers =
    "Texture m_tex_" ~ name ~ ";" ~
    "Sprite m_sprite_" ~ name ~ ";";
}

auto removeElement(R, N)(R haystack, N needle)
{
    import std.algorithm : countUntil, remove;
    auto index = haystack.countUntil(needle);
    return (index != -1) ? haystack.remove(index) : haystack;
}
