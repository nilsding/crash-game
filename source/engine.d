import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.Font;
import Dgame.System.Keyboard;
import Dgame.System.StopWatch;
import Dgame.Window.Event;
import Dgame.Window.Window;

import std.stdio;
import std.string;
import std.signals;

import button;
import board;
import utils;

enum GameScreen
{
  MainMenu,
  PlayBoard
}

template InitButton(string name, string text, string position, string foregroundColor, string backgroundColor)
{
  const char[] InitButton =
    "m_" ~ name ~ " = new Button(this);\n" ~
    "m_" ~ name ~ ".onClick.connect(&" ~ name ~ "_onClick);\n" ~
    "m_" ~ name ~ ".initialize(Vector2i(WIDTH - Button.WIDTH - 22, 22 + Button.HEIGHT * " ~ position ~ " + 9 * " ~ position ~ `), "` ~ text ~ `", ` ~ foregroundColor ~ `, ` ~ backgroundColor ~ `);`;
}

class Engine
{
  @property pure Board board() { return m_board; }
  @property pure bool running() { return m_running; }
  @property pure ref Window window() { return m_window; }
  @property pure ref Button newGameButton() { return m_newGameButton; }
  @property pure ref Font defaultFont() { return m_defaultFont; }

  @property void currentScreen(GameScreen gameScreen)
  {
    m_currentScreen = gameScreen;
    switch (gameScreen)
    {
    case GameScreen.MainMenu:
      m_board.visible = false;
      m_newGameButton.visible = true;
      m_addLineButton.visible = false;
      m_pawsButton.visible = false;
      break;

    case GameScreen.PlayBoard:
      m_board.visible = true;
      m_newGameButton.visible = true;
      m_addLineButton.visible = true;
      m_pawsButton.visible = true;
      break;

    default: goto case GameScreen.MainMenu;
    }
  }

  static const int WIDTH = 800;
  static const int HEIGHT = 480;
  static const ubyte FPS = 60;
  static const ubyte TICKS_PER_FRAME = 1000 / FPS;
  static const string WINDOW_TITLE = "CrashGame";

  mixin Signal!(Event) onMouseDown;
  mixin Signal!(Event) onMouseMove;

  this()
  {
    m_window = Window(WIDTH, HEIGHT, WINDOW_TITLE);
    m_window.setClearColor(Color4b.Black);
    m_window.clear();
    m_window.display();
  }

  void initialize()
  {
    mixin(LoadSprite!("background", "data/background.png"));

    m_defaultFont = Font("data/fonts/visitor1.ttf", 20);  // TODO: this crashes the game (lol!) when exiting, figure out why

    m_board = new Board(this);
    m_board.initialize();

    mixin(InitButton!("newGameButton", "New Game", "0", "Color4b.White", "Color4b(100, 149, 237)"));
    mixin(InitButton!("addLineButton", "Add Line", "1", "Color4b.White", "Color4b(219, 112, 147)"));
    mixin(InitButton!("pawsButton", "Pause", "2", "Color4b.White", "Color4b(255, 255, 0)"));

    currentScreen = GameScreen.MainMenu;
  }

  void mainLoop()
  {
    while (m_running)
    {
      if (m_stopWatch.getElapsedTicks() >= TICKS_PER_FRAME)
      {
        pollEvents();
        update(m_stopWatch);

        m_window.clear();
        draw();
        m_window.display();

        m_stopWatch.reset();
      }
    }
  }

  void pollEvents()
  {
    Event event;

    while (m_window.poll(&event))
    {
      switch (event.type)
      {
      case Event.Type.Quit:
        writeln("Quitting...");
        m_running = false;
        break;

      case Event.Type.MouseMotion:
        onMouseMove.emit(event);
        break;
      case Event.Type.MouseButtonDown:
        onMouseDown.emit(event);
        break;

      case Event.Type.KeyDown:
        handleKeyDown(event);
        break;

      default:
        break;
      }
    }
  }

  void draw()
  {
    m_window.draw(m_sprite_background);

    m_newGameButton.draw();

    switch (m_currentScreen)
    {
    case GameScreen.MainMenu:
      drawString("Main Menu", Vector2i(250, 66), Color4b.White);
      break;

    case GameScreen.PlayBoard:
      m_addLineButton.draw();
      m_pawsButton.draw();
      m_board.draw();

      drawString("Score: %d".format(m_board.score), Vector2i(360, 66), Color4b.White);
      drawString(gameOverText, Vector2i(360, 90), Color4b.White);
      drawString("Lines: %d".format(m_board.linesAdded), Vector2i(360, 114), Color4b.White);

      drawString("Debug:",                                 Vector2i(360, 306 + 20 * 0), Color4b.White);
      drawString("  Delay => %d".format(m_board.delay),    Vector2i(360, 306 + 20 * 1), Color4b.White);
      drawString("  Level => %d".format(m_board.level),    Vector2i(360, 306 + 20 * 2), Color4b.White);
      drawString("  Colours => %d".format(m_board.colors), Vector2i(360, 306 + 20 * 3), Color4b.White);
      drawString("  FPS: %d".format(fps()),                Vector2i(360, 306 + 20 * 4), Color4b.White);
      break;

    default: break;
    }
  }

  void update(ref StopWatch stopWatch)
  {
    switch (m_currentScreen)
    {
    case GameScreen.MainMenu: break;

    case GameScreen.PlayBoard:
      m_board.update(stopWatch);
      break;

    default: break;
    }
  }

  void startNewGame()
  {
    m_board.reset();
    m_board.active = true;
  }

  void addNewLine()
  {
    if (m_board.gameOver || !m_board.active) return;
    m_board.newLine();
  }

  void pauseGame()
  {
    if (m_board.gameOver) return;

    m_board.active = !m_board.active;
    m_window.setTitle(m_board.active ? WINDOW_TITLE : "=== PAUSED ===");
    m_pawsButton.text = m_board.active ? "Pause" : "Resume";
  }

  void drawString(string str, Vector2i position, Color4b color)
  {
    Text text = new Text(m_defaultFont, str);
    text.mode = Font.Mode.Blended;
    text.foreground = color;
    text.setPosition(position.x, position.y);
    m_window.draw(text);
  }

private:
  Window m_window;
  bool m_running = true;
  StopWatch m_stopWatch;
  Font m_defaultFont;
  GameScreen m_currentScreen;

  Board m_board;
  Button m_newGameButton;
  Button m_addLineButton;
  Button m_pawsButton;

  mixin(SpriteMembers!("background"));

  void newGameButton_onClick()
  {
    currentScreen = GameScreen.PlayBoard;
    startNewGame();
  }

  void addLineButton_onClick()
  {
    addNewLine();
  }

  void pawsButton_onClick()
  {
    pauseGame();
  }

  void handleKeyDown(Event event)
  {
    switch (m_currentScreen)
    {
    case GameScreen.MainMenu:
      if (event.keyboard.key == Keyboard.Key.Esc)
        m_window.push(Event.Type.Quit);
      break;

    case GameScreen.PlayBoard:
      switch (event.keyboard.key)
      {
      case Keyboard.Key.Esc:
        m_board.reset();
        currentScreen = GameScreen.MainMenu;
        break;

      case Keyboard.Key.P:
        pauseGame();
        break;

      case Keyboard.Key.Space:
        addNewLine();
        break;

      default: break;
      }
      break;

    default: break;
    }
  }

  int fps()
  {
    return 1000 / m_stopWatch.getElapsedTicks();
  }

  string gameOverText()
  {
    return m_board.gameOver ? "Game over!" : "";
  }
}
