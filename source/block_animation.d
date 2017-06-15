import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.StopWatch;
import Dgame.Window.Window;

import block;
import engine;
import utils;

import std.math;

class BlockAnimation
{
  @property pure Vector2i originBoardLocation() { return m_originBoardLocation; }
  @property void originBoardLocation(Vector2i originBoardLocation)
  {
    m_originBoardLocation = originBoardLocation;
    m_currentPosition = Vector2i(originBoardLocation.x * Block.WIDTH, originBoardLocation.y * Block.WIDTH);
  }
  @property pure Vector2i destinationBoardLocation() { return m_destinationBoardLocation; }
  @property void destinationBoardLocation(Vector2i destinationBoardLocation)
  {
    m_destinationBoardLocation = destinationBoardLocation;
    m_destinationPosition = Vector2i(destinationBoardLocation.x * Block.WIDTH, destinationBoardLocation.y * Block.WIDTH);
  }
  @property pure Block block() { return m_block; }
  @property void block(Block block)
  {
    if (m_block) m_block.animating = false;
    block.animating = true;
    m_block = block;
  }
  @property pure bool falling() { return m_currentPosition.y != m_destinationPosition.y; }

  static const int SPEED = 400;

  this(Engine e)
  {
    m_engine = e;
  }

  void initialize(Block block, Vector2i originBoardLocation, Vector2i destinationBoardLocation)
  {
    mixin(LoadSprite!("block", "data/block.png"));
    mixin(LoadSprite!("block_bomb", "data/block_bomb.png"));
    mixin(LoadSprite!("color_bomb", "data/color_bomb.png"));
    mixin(LoadSprite!("solid_block", "data/solid_block.png"));

    this.block = block;
    this.originBoardLocation = originBoardLocation;
    this.destinationBoardLocation = destinationBoardLocation;
  }

  void draw()
  {
    if (!m_block.visible) return;
    auto sprite = toSprite(m_block.blockType);

    sprite.setColor(m_block.blockColor.toColor());
    sprite.setPosition(m_currentPosition.x + m_engine.board.offset.x, m_currentPosition.y + m_engine.board.offset.y);
    m_engine.window.draw(sprite);
  }

  void update(ref StopWatch stopWatch)
  {
    int diff = cast(int)(SPEED * stopWatch.getElapsedTicks() / 1000.0);

    if (m_engine.board.hasFallingBlocks)
    {
      if (m_destinationPosition.y > m_currentPosition.y)
        m_currentPosition.y += diff;
      else if (m_destinationPosition.y < m_currentPosition.y)
        m_currentPosition.y -= diff;
      if (abs(m_destinationPosition.y - m_currentPosition.y) < diff)
        m_currentPosition.y = m_destinationPosition.y;
    }
    else
    {
      if (m_destinationPosition.x > m_currentPosition.x)
        m_currentPosition.x += diff;
      else if (m_destinationPosition.x < m_currentPosition.x)
        m_currentPosition.x -= diff;
      if (abs(m_destinationPosition.x - m_currentPosition.x) < diff)
        m_currentPosition.x = m_destinationPosition.x;
    }

    if (m_currentPosition == m_destinationPosition)
      m_block.animating = false;
  }

private:
  Engine m_engine;
  Vector2i m_originBoardLocation = Vector2i(0, 0);
  Vector2i m_currentPosition = Vector2i(0, 0);
  Vector2i m_destinationBoardLocation = Vector2i(0, 0);
  Vector2i m_destinationPosition = Vector2i(0, 0);
  Block m_block;

  mixin(SpriteMembers!("block"));
  mixin(SpriteMembers!("block_bomb"));
  mixin(SpriteMembers!("color_bomb"));
  mixin(SpriteMembers!("solid_block"));

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
