import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.StopWatch;
import Dgame.Window.Window;

import engine;
import utils;

enum BlockType
{
  None,
  Default,
  BlockBomb,
  ColorBomb,
  Solid
}

enum BlockColor
{
  None,
  Red,
  Green,
  Blue,
  Yellow,
  White,
  Purple,
  Orange,
  Gold
}

Color4b toColor(BlockColor blockColor)
{
  switch (blockColor)
  {
  case BlockColor.None:   return Color4b(200, 200, 200);
  case BlockColor.Red:    return Color4b(220, 20, 60);
  case BlockColor.Green:  return Color4b(0, 255, 0);
  case BlockColor.Blue:   return Color4b(0, 255, 255);
  case BlockColor.Yellow: return Color4b(255, 255, 0);
  case BlockColor.White:  return Color4b(255, 255, 255);
  case BlockColor.Purple: return Color4b(238, 130, 238);
  case BlockColor.Orange: return Color4b(255, 165, 255);
  case BlockColor.Gold:   return Color4b(252, 255, 95);
  default:                return Color4b(200, 200, 200);
  }
}

class Block
{
  @property pure Vector2i boardPosition() { return m_boardPosition; }
  @property void boardPosition(Vector2i boardPosition) { m_boardPosition = boardPosition; updateSpritePosition(); }
  @property pure Vector2i additionalOffset() { return m_additionalOffset; }
  @property void additionalOffset(Vector2i additionalOffset) { m_additionalOffset = additionalOffset;
                                                               updateSpritePosition(); }
  @property pure BlockColor blockColor() { return m_blockColor; }
  @property void blockColor(BlockColor blockColor) { m_blockColor = blockColor; }
  @property pure BlockType blockType() { return m_blockType; }
  @property void blockType(BlockType blockType) { m_blockType = blockType; }
  @property pure bool visible() { return m_blockType != BlockType.None; }
  @property pure bool selected() { return m_selected; }
  @property void selected(bool selected) { m_selected = selected; }
  @property pure bool tempSelected() { return m_tempSelected; }
  @property void tempSelected(bool tempSelected) { m_tempSelected = tempSelected; }
  @property pure bool animating() { return m_animating; }
  @property void animating(bool animating) { m_animating = animating; }

  static const int WIDTH = 22;

  this(Engine e)
  {
    m_engine = e;
  }

  void initialize()
  {
    mixin(LoadSprite!("block", "data/block.png"));
    mixin(LoadSprite!("block_bomb", "data/block_bomb.png"));
    mixin(LoadSprite!("color_bomb", "data/color_bomb.png"));
    mixin(LoadSprite!("solid_block", "data/solid_block.png"));
  }

  void draw()
  {
    if (!visible || animating) return;
    auto sprite = toSprite(m_blockType);

    sprite.setColor(blockColor.toColor());
    m_engine.window.draw(sprite);
    if (m_tempSelected)
    {
      sprite.setColor(Color4b(255, 255, 255, 127));
      m_engine.window.draw(sprite);
    }
  }

  void update(ref StopWatch stopWatch)
  {
  }

private:
  Engine m_engine;
  Vector2i m_boardPosition = Vector2i(0, 0);
  Vector2i m_additionalOffset = Vector2i(0, 0);
  BlockColor m_blockColor = BlockColor.None;
  BlockType m_blockType = BlockType.None;
  bool m_selected = false;
  bool m_tempSelected = false;
  bool m_animating = false;

  mixin(SpriteMembers!("block"));
  mixin(SpriteMembers!("block_bomb"));
  mixin(SpriteMembers!("color_bomb"));
  mixin(SpriteMembers!("solid_block"));

  void updateSpritePosition()
  {
    const int x = m_boardPosition.x * WIDTH + m_engine.board.offset.x + m_additionalOffset.x;
    const int y = m_boardPosition.y * WIDTH + m_engine.board.offset.y + m_additionalOffset.y;
    m_sprite_block.setPosition(x, y);
    m_sprite_block_bomb.setPosition(x, y);
    m_sprite_color_bomb.setPosition(x, y);
    m_sprite_solid_block.setPosition(x, y);
  }

  Sprite toSprite(BlockType type)
  {
    switch (type)
    {
    case BlockType.BlockBomb: return m_sprite_block_bomb;
    case BlockType.ColorBomb: return m_sprite_color_bomb;
    case BlockType.Solid: return m_sprite_solid_block;
    default: return m_sprite_block;
    }
  }
}
