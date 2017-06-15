import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.StopWatch;
import Dgame.Window.Window;
import Dgame.Window.Event;

import block;
import block_animation;
import engine;
import utils;

import std.container.array;
import std.math;
import std.stdio;
import std.string;
import std.random;

class Board
{
  @property Vector2i offset() { return m_offset; }
  @property void offset(Vector2i offset) { m_offset = offset; }
  @property bool visible() { return m_visible; }
  @property void visible(bool visible) { m_visible = visible; }
  @property bool active() { return m_active; }
  @property void active(bool active) { m_active = active; }
  @property bool gameOver() { return m_gameOver; }
  @property void gameOver(bool gameOver) { m_gameOver = gameOver; }
  @property uint colors() { return m_colors; }
  @property void colors(uint colors)
  {
    if      (colors < 3) m_colors = 3;
    else if (colors > 7) m_colors = 7;
    else                 m_colors = colors;
  }
  @property uint delay() { return m_delay; }
  @property void delay(uint delay) { m_delay = delay; m_delayPart = delay / COLUMNS; }
  @property uint score() { return m_score; }
  @property uint level() { return m_level; }
  @property uint linesAdded() { return m_linesAdded; }

  static const int COLUMNS = 12;
  static const int ROWS = 16;

  static const Vector2i SHADOW_OFFSET = Vector2i(21, 21);

  this(Engine e)
  {
    m_engine = e;

    e.onMouseMove.connect(&onMouseMove);
    e.onMouseDown.connect(&onMouseDown);
  }

  void initialize()
  {
    mixin(LoadSprite!("board", "data/board.png"));

    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        m_blocks[x][y] = new Block(m_engine);
        m_blocks[x][y].initialize();
        m_blocks[x][y].boardPosition = Vector2i(x, y);
      }
      m_preview[x] = new Block(m_engine);
      m_preview[x].initialize();
      m_preview[x].boardPosition = Vector2i(x, 0);
      m_preview[x].additionalOffset = Vector2i(0, ROWS * Block.WIDTH + 8);
    }
    reset();
  }

  void reset()
  {
    delay = 7.seconds;
    m_active = false;
    m_gameOver = false;
    m_remainingDelayPart = m_delayPart;
    m_remainingFillDelay = m_fillDelay;
    m_currpos = 0;
    m_score = 0;
    colors = 3;
    m_linesAdded = 0;
    m_blocksDestroyed = 0;
    m_blockAnimations = [];

    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        m_blocks[x][y].blockType = BlockType.None;
        m_blocks[x][y].blockColor = BlockColor.None;
      }
      m_preview[x].blockType = BlockType.None;
      m_preview[x].blockColor = BlockColor.None;
    }
  }

  void draw()
  {
    m_sprite_board.setPosition(m_offset.x - SHADOW_OFFSET.x, m_offset.y - SHADOW_OFFSET.y);
    m_engine.window.draw(m_sprite_board);

    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        m_blocks[x][y].draw();
      }
      m_preview[x].draw();
    }

    foreach (blockAnimation; m_blockAnimations)
    {
      blockAnimation.draw();
    }
  }

  void update(ref StopWatch stopWatch)
  {
    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        m_blocks[x][y].update(stopWatch);
      }
    }

    BlockAnimation[] finishedAnimations;
    foreach (blockAnimation; m_blockAnimations)
    {
      blockAnimation.update(stopWatch);
      if (!blockAnimation.block.animating)
        finishedAnimations ~= blockAnimation;
    }
    foreach (blockAnimation; finishedAnimations)
    {
      m_blockAnimations = m_blockAnimations.removeElement(blockAnimation);
    }

    if (gameOver)
    {
      m_remainingFillDelay -= stopWatch.getElapsedTicks();
      if (m_remainingFillDelay <= 0)
      {
        m_remainingFillDelay = m_fillDelay;
        auto block = findFirstInvisibleBlock();
        if (block)
        {
          block.blockColor = BlockColor.Gold;
          block.blockType = BlockType.Solid;
        }
      }
    }

    if (!m_active)
    {
      return;
    }

    m_remainingDelayPart -= stopWatch.getElapsedTicks();
    if (m_remainingDelayPart <= 0)
    {
      m_remainingDelayPart = m_delayPart;
      if (m_currpos < COLUMNS)
      {
        newPreviewBlock();
      }
      else
      {
        movePreviewToBlockField();
        m_currpos = 0;
      }
    }
  }

  void onMouseMove(Event event)
  {
    if (!m_active)
    {
      return;
    }

    if (event.mouse.motion.x < m_offset.x || event.mouse.motion.y < m_offset.y)
    {
      return;
    }

    auto boardPosition = Vector2i(
      (event.mouse.motion.x - m_offset.x) / Block.WIDTH,
      (event.mouse.motion.y - m_offset.y) / Block.WIDTH
    );

    resetSelection();
    selectBlock(boardPosition, true);
  }

  void onMouseDown(Event event)
  {
    if (!m_active)
    {
      return;
    }

    if (event.mouse.button.x < m_offset.x || event.mouse.button.y < m_offset.y)
    {
      return;
    }
    auto boardPosition = Vector2i(
      (event.mouse.button.x - m_offset.x) / Block.WIDTH,
      (event.mouse.button.y - m_offset.y) / Block.WIDTH
    );

    resetSelection();
    if (!selectBlock(boardPosition, false))
    {
      return;
    }

    auto activeBlock = m_blocks[boardPosition.x][boardPosition.y];
    if (activeBlock.blockType == BlockType.Default)
    {
      if (m_selected >= 3)
      {
        recalculateScore();
        removeAllSelected();
      }
    }
    else if (activeBlock.blockType != BlockType.Solid)
    {
      recalculateScore();
      removeAllSelected();
    }
    resetSelection();
  }

  void newLine()
  {
    if (!m_active)
    {
      return;
    }

    while (m_currpos < COLUMNS)
    {
      newPreviewBlock();
    }
    movePreviewToBlockField();
    m_currpos = 0;
  }

  bool hasFallingBlocks()
  {
    foreach (blockAnimation; m_blockAnimations)
    {
      if (blockAnimation.falling) return true;
    }
    return false;
  }

private:
  Engine m_engine;
  Vector2i m_offset = Vector2i(50, 40);
  bool m_visible = false;
  bool m_active = false;
  bool m_gameOver = false;
  Block[ROWS][COLUMNS] m_blocks;
  Block[COLUMNS] m_preview;
  uint m_currpos = 0;
  uint m_colors = 3;
  uint m_delay = 0;
  uint m_delayPart = 0;
  int m_remainingDelayPart = 0;
  uint m_fillDelay = 30;
  int m_remainingFillDelay;
  uint m_selected = 0;
  uint m_score = 0;
  uint m_blocksDestroyed = 0;
  uint m_level = 0;
  uint m_linesAdded = 0;
  BlockAnimation[] m_blockAnimations;

  mixin(SpriteMembers!("board"));

  bool selectBlock(Vector2i boardPosition, bool tempSelect)
  {
    if (!(boardPosition.x >= 0
          && boardPosition.x < COLUMNS
          && boardPosition.y >= 0
          && boardPosition.y < ROWS))
    {
      return false;
    }

    switch (m_blocks[boardPosition.x][boardPosition.y].blockType) with(BlockType)
    {
    case ColorBomb:
      scanColorBomb(boardPosition, tempSelect);
      break;
    case BlockBomb:
      scanBlockBomb(boardPosition, tempSelect);
      break;
    case Solid:
      break;
    default:
      startScan(boardPosition, tempSelect);
      break;
    }
    return true;
  }

  void selectBlock(Block block, bool tempSelect)
  {
    if (tempSelect)
      block.tempSelected = true;
    else
      block.selected = true;
    m_selected++;
  }

  void scanColorBomb(Vector2i boardPosition, bool tempSelect)
  {
    auto blockColor = m_blocks[boardPosition.x][boardPosition.y].blockColor;
    m_selected = 0;

    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        if (m_blocks[x][y].blockColor == blockColor)
        {
          selectBlock(m_blocks[x][y], tempSelect);
        }
      }
    }
  }

  void scanBlockBomb(Vector2i boardPosition, bool tempSelect)
  {
    auto origin = m_blocks[boardPosition.x][boardPosition.y];
    m_selected = 0;

    if (boardPosition.x - 1 >= 0 && boardPosition.y - 1 >= 0)
      selectBlock(m_blocks[boardPosition.x - 1][boardPosition.y - 1], tempSelect);
    if (boardPosition.x - 1 >= 0)
      selectBlock(m_blocks[boardPosition.x - 1][boardPosition.y],     tempSelect);
    if (boardPosition.x - 1 >= 0 && boardPosition.y + 1 < ROWS)
      selectBlock(m_blocks[boardPosition.x - 1][boardPosition.y + 1], tempSelect);

    if (boardPosition.y - 1 >= 0)
      selectBlock(m_blocks[boardPosition.x][boardPosition.y - 1],     tempSelect);
    selectBlock(origin, tempSelect);
    if (boardPosition.y + 1 < ROWS)
      selectBlock(m_blocks[boardPosition.x][boardPosition.y + 1],     tempSelect);

    if (boardPosition.x + 1 < COLUMNS && boardPosition.y - 1 >= 0)
      selectBlock(m_blocks[boardPosition.x + 1][boardPosition.y - 1], tempSelect);
    if (boardPosition.x + 1 < COLUMNS)
      selectBlock(m_blocks[boardPosition.x + 1][boardPosition.y],     tempSelect);
    if (boardPosition.x + 1 < COLUMNS && boardPosition.y + 1 < ROWS)
      selectBlock(m_blocks[boardPosition.x + 1][boardPosition.y + 1], tempSelect);
  }

  void startScan(Vector2i boardPosition, bool tempSelect)
  {
    auto block = m_blocks[boardPosition.x][boardPosition.y];
    m_selected = 0;

    if (!block.visible)
    {
      return;
    }

    if (tempSelect)
      block.tempSelected = true;
    else
      block.selected = true;
    m_selected = 1;

    scan(boardPosition, tempSelect);
  }

  void scan(Vector2i boardPosition, bool tempSelect)
  {
    int count = 0;
    auto origin = m_blocks[boardPosition.x][boardPosition.y];

    if (boardPosition.x - 1 >= 0)
      count += check(origin, m_blocks[boardPosition.x - 1][boardPosition.y], tempSelect);
    if (boardPosition.y - 1 >= 0)
      count += check(origin, m_blocks[boardPosition.x][boardPosition.y - 1], tempSelect);
    if (boardPosition.y + 1 < ROWS)
      count += check(origin, m_blocks[boardPosition.x][boardPosition.y + 1], tempSelect);
    if (boardPosition.x + 1 < COLUMNS)
      count += check(origin, m_blocks[boardPosition.x + 1][boardPosition.y], tempSelect);

    m_selected += count;
  }

  int check(Block origin, Block next, bool tempSelect = false)
  {
    if ((tempSelect && !next.tempSelected && next.blockColor == origin.blockColor)
         || (!tempSelect && !next.selected && next.blockColor == origin.blockColor))
    {
      if (tempSelect)
        next.tempSelected = true;
      else
        next.selected = true;
      scan(next.boardPosition, tempSelect);
      return 1;
    }
    return 0;
  }

  void removeAllSelected()
  {
    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        if (m_blocks[x][y].selected)
        {
          m_blocks[x][y].blockColor = BlockColor.None;
          m_blocks[x][y].blockType = BlockType.None;
          m_blocks[x][y].selected = false;
          m_blocks[x][y].tempSelected = false;
        }
      }
    }
    m_selected = 0;

    moveBlocksDown();
    moveBlocksCenter();
  }

  void moveBlocksDown()
  {
    int moved;
    do
    {
      moved = 0;
      for (int y = 1; y < ROWS; y++)
      {
        for (int x = 0; x < COLUMNS; x++)
        {
          if (m_blocks[x][y].visible) continue;
          if (!m_blocks[x][y - 1].visible) continue;
          m_blocks[x][y].blockColor = m_blocks[x][y - 1].blockColor;
          m_blocks[x][y].blockType = m_blocks[x][y - 1].blockType;
          m_blocks[x][y - 1].blockColor = BlockColor.None;
          m_blocks[x][y - 1].blockType = BlockType.None;
          animateBlock(m_blocks[x][y], Vector2i(x, y - 1), Vector2i(x, y));
          moved++;
        }
      }
    } while (moved > 0);
  }

  void moveBlocksCenter()
  {
    // Moving blocks to the center is kinda tricky.
    // First we move all blocks to the left, then decide how many blocks we should move to the right.
    do
    {
      for (int x = 0; x < COLUMNS - 1; x++)
      {
        if (!(isColumnEmpty(x) && !isColumnEmpty(x + 1))) continue;
        for (int y = 0; y < ROWS; y++)
        {
          m_blocks[x][y].blockColor = m_blocks[x + 1][y].blockColor;
          m_blocks[x][y].blockType = m_blocks[x + 1][y].blockType;
          m_blocks[x + 1][y].blockColor = BlockColor.None;
          m_blocks[x + 1][y].blockType = BlockType.None;
          animateBlock(m_blocks[x][y], Vector2i(x + 1, y), Vector2i(x, y));
        }
      }
    } while (countGaps() > 1);

    int space = 0;
    for (int x = 0; x < COLUMNS; x++)
    {
      if (!m_blocks[x][ROWS - 1].visible)
      {
        space++;
      }
    }

    int pullRightCount = cast(int)(space / 2.0).floor;
    if (pullRightCount > 0)
    {
      for (int x = COLUMNS - pullRightCount; x >= pullRightCount; x--)
      {
        for (int y = 0; y < ROWS; y++)
        {
          m_blocks[x][y].blockColor = m_blocks[x - pullRightCount][y].blockColor;
          m_blocks[x][y].blockType = m_blocks[x - pullRightCount][y].blockType;
          m_blocks[x - pullRightCount][y].blockColor = BlockColor.None;
          m_blocks[x - pullRightCount][y].blockType = BlockType.None;
          animateBlock(m_blocks[x][y], Vector2i(x - pullRightCount, y), Vector2i(x, y));
        }
      }
    }
  }

  pure bool isColumnEmpty(int column)
  {
    for (int y = ROWS - 1; y >= 0; y--)
    {
      if (m_blocks[column][y].visible) return false;
    }
    return true;
  }

  pure int countGaps()
  {
    int gaps = 0;
    bool currentVisible = m_blocks[0][ROWS - 1].visible;
    for (int x = 1; x < COLUMNS; x++)
    {
      if (currentVisible == m_blocks[x][ROWS - 1].visible) continue;
      gaps++;
      currentVisible = m_blocks[x][ROWS - 1].visible;
    }
    return gaps;
  }

  void resetSelection()
  {
    for (int x = 0; x < COLUMNS; x++)
    {
      for (int y = 0; y < ROWS; y++)
      {
        m_blocks[x][y].selected = false;
        m_blocks[x][y].tempSelected = false;
      }
    }
  }

  void recalculateScore()
  {
    m_blocksDestroyed += m_selected;

    m_score += m_selected * 10 * m_level;
    m_level = m_blocksDestroyed / 30 + 1;
    delay = cast(uint)((7 - ((10 * log10(m_level) + 1) / 3)) * 1000).floor;
    colors = m_blocksDestroyed / 85;
  }

  void newPreviewBlock()
  {
    auto currpos = m_currpos++;
    m_preview[currpos].blockType = BlockType.Default;
    m_preview[currpos].blockColor = cast(BlockColor) uniform(1, m_colors + 1);

    if (colors <= 3) return;

    if (dice(99, 1) == 1)  // 1% probability for a solid block
    {
      m_preview[currpos].blockType = BlockType.Solid;
      m_preview[currpos].blockColor = BlockColor.None;
      return;
    }

    if (dice(98, 2) == 1)  // 2% probability for a bomb of any kind
    {
      m_preview[currpos].blockType = BlockType.ColorBomb;  // most common: color bomb
      if (dice(60, 40) == 1)
        m_preview[currpos].blockType = BlockType.BlockBomb;
    }
  }

  void movePreviewToBlockField()
  {
    if (!firstRowEmpty())
    {
      doGameOver();
      return;
    }

    for (int y = 1; y < ROWS; y++)
    {
      for (int x = 0; x < COLUMNS; x++)
      {
        m_blocks[x][y - 1].blockColor = m_blocks[x][y].blockColor;
        m_blocks[x][y - 1].blockType = m_blocks[x][y].blockType;
      }
    }

    for (int x = 0; x < COLUMNS; x++)
    {
      m_blocks[x][ROWS - 1].blockColor = m_preview[x].blockColor;
      m_blocks[x][ROWS - 1].blockType = m_preview[x].blockType;
      m_preview[x].blockColor = BlockColor.None;
      m_preview[x].blockType = BlockType.None;
    }

    m_linesAdded++;
  }

  pure bool firstRowEmpty()
  {
    for (int x = 0; x < COLUMNS; x++)
    {
      if (m_blocks[x][0].visible) return false;
    }
    return true;
  }

  void doGameOver()
  {
    writeln("Game over!");
    m_active = false;
    m_gameOver = true;
    resetSelection();
  }

  void animateBlock(Block block, Vector2i originBoardLocation, Vector2i destinationBoardLocation)
  {
    auto blockAnimation = blockAnimationForDestination(originBoardLocation);
    if (blockAnimation)
    {
      blockAnimation.block = block;
      blockAnimation.destinationBoardLocation = destinationBoardLocation;
      return;
    }
    blockAnimation = new BlockAnimation(m_engine);
    blockAnimation.initialize(block, originBoardLocation, destinationBoardLocation);
    m_blockAnimations ~= blockAnimation;
  }

  pure BlockAnimation blockAnimationForDestination(Vector2i destination)
  {
    foreach (blockAnimation; m_blockAnimations)
    {
      if (blockAnimation.destinationBoardLocation == destination) { return blockAnimation; }
    }
    return null;
  }

  pure Block findFirstInvisibleBlock()
  {
    for (int y = 0; y < ROWS; y++)
    {
      for (int x = 0; x < COLUMNS; x++)
      {
        if (!m_blocks[x][y].visible) { return m_blocks[x][y]; }
      }
    }
    return null;
  }
}
