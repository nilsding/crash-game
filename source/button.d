import Dgame.Graphic;
import Dgame.Graphic.Text;
import Dgame.Math;
import Dgame.System.Font;
import Dgame.System.StopWatch;
import Dgame.Window.Window;
import Dgame.Window.Event;

import engine;
import utils;

import std.stdio;
import std.signals;

class Button
{
  @property pure Vector2i offset() { return m_offset; }
  @property void offset(Vector2i offset) { m_offset = offset; }
  @property pure bool visible() { return m_visible; }
  @property void visible(bool visible) { m_visible = visible; }
  @property pure Color4b foregroundColor() { return m_foregroundColor; }
  @property void foregroundColor(Color4b foregroundColor) { m_foregroundColor = foregroundColor; }
  @property pure Color4b backgroundColor() { return m_backgroundColor; }
  @property void backgroundColor(Color4b backgroundColor) { m_backgroundColor = backgroundColor; }
  @property pure string text() { return m_text.getText(); }
  @property void text(string text) { m_text.setData(text); }

  static const int WIDTH = 266;
  static const int HEIGHT = 66;

  mixin Signal!() onClick;

  this(Engine e)
  {
    m_engine = e;
    e.onMouseDown.connect(&onMouseDown);
  }

  void initialize(Vector2i offset, string text, Color4b foregroundColor, Color4b backgroundColor)
  {
    m_offset = offset;
    m_foregroundColor = foregroundColor;
    m_backgroundColor = backgroundColor;
    m_text = new Text(m_engine.defaultFont);
    m_text.setData(text);
    m_text.mode = Font.Mode.Blended;
    m_text.foreground = foregroundColor;
    mixin(LoadSprite!("menu_button", "data/menu_button.png"));
  }

  void draw()
  {
    if (!m_visible)
    {
      return;
    }

    m_sprite_menu_button.setPosition(m_offset.x, m_offset.y);
    m_sprite_menu_button.setColor(m_backgroundColor);
    m_engine.window.draw(m_sprite_menu_button);
    m_text.setPosition((m_offset.x + WIDTH / 2f - m_text.width / 2f), (m_offset.y + HEIGHT / 2f - m_text.height / 2f - 2));
    m_engine.window.draw(m_text);
  }

  void update(ref StopWatch stopWatch)
  {
  }

  void onMouseDown(Event event)
  {
    if (!m_visible
        || event.mouse.button.x < m_offset.x || event.mouse.button.y < m_offset.y
        || event.mouse.button.x > m_offset.x + WIDTH || event.mouse.button.y > m_offset.y + HEIGHT)
    {
      return;
    }
    onClick.emit();
  }

private:
  Engine m_engine;
  Vector2i m_offset;
  bool m_visible = false;
  Color4b m_foregroundColor = Color4b.Black;
  Color4b m_backgroundColor = Color4b.White;
  Font m_font;
  Text m_text;

  mixin(SpriteMembers!("menu_button"));
}
