unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ImgList, Buttons;

type
  { ** Small array to contain TShapes to display on the title screen
    ** as preview for the customizable Snake}
  PreviewSnake = Array[1..5] of TShape;

  { ** Initial Form }
  TWindow = class(TForm)
    PlaySingleplayer: TButton;
    Playername: TEdit;
    PlayernameLabel: TLabel;
    HighscorePanel: TPanel;
    TabControl: TTabControl;
    SnakeDesignPanel: TPanel;
    BackgroundDesignPanel: TPanel;
    HeadColorBox: TColorBox;
    PrimaryColorBox: TColorBox;
    SecondaryColorBox: TColorBox;
    PrimaryColorLabel: TLabel;
    SecondaryColorLabel: TLabel;
    TitleScreen: TPanel;
    HeadColorLabel: TLabel;
    DirtImageList: TImageList;
    GrassImageList: TImageList;
    SandImageList: TImageList;
    StoneImageList: TImageList;
    BackgroundType: TComboBox;
    SelectedBackgroundImage: TImage;
    LabelSelectedBackground: TLabel;
    ItemList: TImageList;
    CloseButton: TButton;
    BarrierList: TImageList;
    HelpPanel: TPanel;
    ShortDescription: TLabel;
    ItemHeadline: TLabel;
    AppleDescription: TLabel;
    PotatoDescription: TLabel;
    PoisonousPotatoDescription: TLabel;
    SnailDescription: TLabel;
    LightningDescription: TLabel;
    GoldenAppleDescription: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure PlaySingleplayerClick(Sender: TObject);
    procedure HeadColorBoxChange(Sender: TObject);
    procedure PrimaryColorBoxChange(Sender: TObject);
    procedure SecondaryColorBoxChange(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PlayernameExit(Sender: TObject);
    procedure BackgroundTypeChange(Sender: TObject);
    procedure OnBitBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CloseButtonClick(Sender: TObject);
  private
    PreviewSnake: PreviewSnake;
    procedure DrawPreviewSnake(var Snake: PreviewSnake);
    procedure ColorBoxChange(Sender: TObject);
  end;


  { ** Class to show temporary messages }
  TMessageSender = class
    Timer: TTimer;
    TextField: TLabel;
    procedure OnTimer(Sender: TObject);
    procedure Send(MSG: String); overload;
    procedure Send(MSG: String; CordX, CordY, Length: Integer); overload;
  end;


  { ** Enumeration for the move direction of the Snake }
  TDirection = (DirUp, DirDown, DirLeft, DirRight);


  { ** Type of the random item spawning sometimes }
  TItemType = (NormalApple, GoldenApple, Lightning, Snail, Potato, PoisonousPotato);


  { ** Record for a pair of coordinates }
  TCoordinatePair = record
    x, y: Integer;
  end;


  { ** Class of the Snake }
  TSnake = class
    BackgroundPanel, Playground: TPanel;
    Direction: TDirection;
    IsKeyListenerBlocked: boolean;
    Body: Array of TShape;
    Timer: TTimer;
    Crashed: boolean;
    Apple: TImage;
    RandomItem: TImage;
    RandomItemType: TItemType;
    RandomItemDespawnTimer: TTimer;
    ScoreCounterLabel, HighestScoreLabel: TLabel;
    Score: Integer;
    PauseButton, EndGameButton: TButton;
    IsPaused: Boolean;
    Barriers: Array of TCoordinatePair;
    IsRandomItemSpawned: Boolean;
    procedure OnEndGameButtonClick(Sender: TObject);
    procedure OnPauseButtonClick(Sender: TObject);
    procedure SetCoordinates(cdX, cdY: Integer; var Shape: TShape); overload;
    procedure SetCoordinates(cdX, cdY: Integer; var Image: TImage); overload;
    procedure OnMove(Sender: TObject);
    procedure DespawnRandomItem(Sender: TObject);
    function WillCrash: boolean;
    procedure EndGame(CallerClosesPlayground: Boolean);
    procedure EatApple;
    procedure EatRandomItem;
    procedure SetApple;
    procedure SetRandomItem;
    function WouldAppleBeOnSnake(cdX, cdY: Integer): boolean;
    procedure IncreaseSpeed;
    constructor Create;
  end;


  { ** Record for the colors of the Snake }
  TSnakeColor = record
    Primary, Secondary, Head: TColor;
  end;


  { ** Enumerates the styles of the background }
  TBackgroundStyle = (Grass, Sand, Stone, Dirt);

  { ** Record by which an exact background is specified }
  TBackground = record
    Style: TBackgroundStyle;
    Index: Integer;
  end;


  { ** Record for the settings of the game, containing the playername, the colors
    ** of the snake, and the exact background }
  TGameSettings = class
    PlayerName: String;
    SnakeColor: TSnakeColor;
    Background: TBackground;
  end;


  { ** Record for Highscores }
  THighScore = record
    Name: String[16];
    Score: Integer;
  end;


  { ** Record which is stored in the file and gives it its structure }
  TFile = record
    PlayerName: String[16];
    SnakeColor: TSnakeColor;
    Background: TBackground;
    HighScore: Array[1..10] of THighScore;
  end;

  { ** Class to create barriers on the playground}
  TBarrier = class
    Timer, PauseChecker: TTimer;
    Image: TImage;
    Coordinates: TCoordinatePair;
    Snake: TSnake;
    procedure DestroyBarrier(Sender: TObject);
    procedure CheckForPause(Sender: TObject);
    constructor CreateBarrier(CordX, CordY: Integer; Time: Integer; var Snake: TSnake);
  end;


var
  Window: TWindow; { ** Initial form }
  Settings: TGameSettings; { ** GameSettings }
  Storage: File of TFile; { ** File, which contains the Settings and Highscores }
  SelectBackgroundButtons: array[0..10] of TBitBtn; { ** Buttons to select the background }
  Snake: TSnake; { ** Snake }
  HighScores: Array[1..10] of THighScore; { ** List of highscores }
  MessageSender: TMessageSender; { ** Instance to send temporary messages}


const
  SnakeWidth = 20; { ** Width and Height of the Snake }
  StorageFileName = 'Snake.snk'; { ** Path where the file will be saved }
  Speed = 400; { ** Speed of the snake in the beginning of the game }
  RandomItemSpawnChance = 20; { ** Chance per move of the snake to spawn a random item}

implementation

{$R *.dfm}


{ ** Sets the default settings if no existing settings were found }
procedure SetDefaults;
var
  f: TFile;
  Color: TSnakeColor;
  i: Integer;
begin
  Settings.Playername := 'Spieler';
  Settings.Background.Style := Grass;
  Settings.Background.Index := 0;
  Color.Head := clRed;
  Color.Primary := clTeal;
  Color.Secondary := clMoneyGreen;
  Settings.SnakeColor := Color;
  f.PlayerName := Settings.PlayerName;
  f.SnakeColor := Settings.SnakeColor;
  f.Background := Settings.Background;
  for i := 1 to 10 do begin
    f.HighScore[i].Name := '';
    f.HighScore[i].Score := 0;
  end;
  Write(Storage, f);
  Seek(Storage, 0);
end;


{ ** Returns the contents of the storage file as TFile }
function GetTFile: TFile;
var
  f: TFile;
begin
  Read(Storage, f);
  Seek(Storage, 0);
  Result := f;
end;


{ ** Loads existing information to the variable Settings }
procedure LoadInformation;
var
  i: Integer;
begin
  Settings.PlayerName := GetTFile.PlayerName;
  Settings.SnakeColor := GetTFile.SnakeColor;
  Settings.Background := GetTFile.Background;
  for i := 1 to 10 do begin
    HighScores[i].Name := GetTFile.HighScore[i].Name;
    HighScores[i].Score := GetTFile.HighScore[i].Score;
  end;
end;


{ ** Returns the bitmap of the ImageList matching to "Style" with the correct "Index" }
function GetBackgroundBitmap(Index: Integer; Style: TBackgroundStyle): TBitmap; overload;
begin
  Result := TBitmap.Create;
  case Style of
    Grass: begin
      Window.GrassImageList.GetBitmap(Index, Result);
    end;
    Sand: begin
      Window.SandImageList.GetBitmap(Index, Result);
    end;
    Stone: begin
      Window.StoneImageList.GetBitmap(Index, Result);
    end;
    Dirt: begin
      Window.DirtImageList.GetBitmap(Index, Result);
    end;
  end;
end;


{ ** Returns the bitmap of the ImageList matching to the BackgroundStyle stored in the Settings and the "Index" }
function GetBackgroundBitmap(Index: Integer): TBitmap; overload;
begin
  Result := GetBackgroundBitmap(Index, Settings.Background.Style);
end;


{ ** FormCreate of TWindow
  ** First important initializations,
  ** Handling the storage file,
  ** Positioning the components }
procedure TWindow.FormCreate(Sender: TObject);
var
  PanelCenter: Integer;
  i: Integer;
  ScoreLabel, NameLabel: TLabel;
begin
  Randomize;

  Window.Width := 1000;
  Window.Height := 500;
  Settings := TGameSettings.Create;

  AssignFile(Storage, StorageFileName);
  if FileExists(StorageFileName) then begin
    Reset(Storage);
    LoadInformation;
    TabControl.TabIndex := Random(4);
  end else begin
    Rewrite(Storage);
    SetDefaults;
    TabControl.TabIndex := 3;
  end;

  TabControlChange(Sender);

  TitleScreen.Width := Window.Width;
  TitleScreen.Height := Window.Height;
  TitleScreen.Top := 0;
  TitleScreen.Left := 0;
  PanelCenter := TitleScreen.Width div 2;

  PlaySingleplayer.Left := PanelCenter - PlaySingleplayer.Width div 2 - 100;
  Playername.Left := PanelCenter - Playername.Width div 2;
  PlayernameLabel.Left := PanelCenter - PlayernameLabel.Width div 2;
  Playername.Text := Settings.PlayerName;
  CloseButton.Left := PanelCenter - CloseButton.Width div 2 + 100;

  BackgroundDesignPanel.Left := PanelCenter - BackgroundDesignPanel.Width div 2;
  SnakeDesignPanel.Left := PanelCenter - SnakeDesignPanel.Width div 2;
  HighscorePanel.Left := PanelCenter - HighscorePanel.Width div 2;
  HelpPanel.Left := PanelCenter - HelpPanel.Width div 2;
  TabControl.Left := PanelCenter - TabControl.Width div 2;

  HeadColorBox.Top := SnakeDesignPanel.Height div 3 - HeadColorBox.Height div 2 - 40;
  PrimaryColorBox.Top := SnakeDesignPanel.Height div 3 - PrimaryColorBox.Height div 2;
  SecondaryColorBox.Top := SnakeDesignPanel.Height div 3 - SecondaryColorBox.Height div 2 + 40;
  HeadColorLabel.Top := HeadColorBox.Top;
  PrimaryColorLabel.Top := PrimaryColorBox.Top;
  SecondaryColorLabel.Top := SecondaryColorBox.Top;
  HeadColorBox.Selected := Settings.SnakeColor.Head;
  PrimaryColorBox.Selected := Settings.SnakeColor.Primary;
  SecondaryColorBox.Selected := Settings.SnakeColor.Secondary;

  for i := 1 to 10 do begin
    if HighScores[i].Name = '' then Break;
    ScoreLabel := TLabel.Create(self);
    NameLabel := TLabel.Create(self);
    ScoreLabel.Parent := HighscorePanel;
    NameLabel.Parent := HighscorePanel;
    ScoreLabel.Caption := IntToStr(HighScores[i].Score);
    NameLabel.Caption := HighScores[i].Name;
    NameLabel.Left := HighscorePanel.Width div 3;
    ScoreLabel.Left := HighscorePanel.Width div 3 * 2;
    ScoreLabel.Top := 20 + i * ScoreLabel.Height;
    NameLabel.Top := 20 + i * NameLabel.Height;
  end;

  BackgroundType.Left := BackgroundDesignPanel.Width div 2 - BackgroundType.Width div 2;

  case Settings.Background.Style of
    Grass: BackgroundType.ItemIndex := 0;
    Sand: BackgroundType.ItemIndex := 1;
    Stone: BackgroundType.ItemIndex := 2;
    Dirt: BackgroundType.ItemIndex := 3;
  end;
  BackgroundTypeChange(Sender);
  SelectedBackgroundImage.Picture.Bitmap.Assign(GetBackgroundBitmap(Settings.Background.Index));

  DrawPreviewSnake(PreviewSnake);
end;


{ ** Creates a preview on the title screen of how the customized Snake will look like }
procedure TWindow.DrawPreviewSnake(var Snake: PreviewSnake);
var
  i: Integer;
begin
  for i := 1 to 5 do begin
    Snake[i] := TShape.Create(self);
    Snake[i].Parent := SnakeDesignPanel;
    Snake[i].Width := SnakeWidth;
    Snake[i].Height := SnakeWidth;
    Snake[i].Left := SnakeDesignPanel.Width div 2 + SnakeWidth * i - 3 * SnakeWidth + SnakeWidth div 2;
    Snake[i].Top := SnakeDesignPanel.Height div 3 * 2 + 20;

    if i mod 2 = 0 then begin
      Snake[i].Brush.Color := Settings.SnakeColor.Primary;
      Snake[i].Pen.Color := Settings.SnakeColor.Secondary;
    end else begin
      Snake[i].Brush.Color := Settings.SnakeColor.Secondary;
      Snake[i].Pen.Color := Settings.SnakeColor.Primary;
    end;
  end;
  Snake[1].Brush.Color := Settings.SnakeColor.Head;
  Snake[1].Pen.Color := Settings.SnakeColor.Head;
  Snake[1].Shape := stRoundSquare;
end;


{ ** OnClickListener for the play button,
  ** Saves settings,
  ** Creates Snake (Calls constructor),
  ** Hides the title screen }
procedure TWindow.PlaySingleplayerClick(Sender: TObject);
var
  f: TFile;
begin
  Settings.PlayerName := Playername.Text;

  f := GetTFile;
  f.PlayerName := Playername.Text;
  Write(Storage, f);
  Seek(Storage, 0);

  TitleScreen.Hide;
  Window.Caption := 'Snake - Einzelspieler';
  Snake := TSnake.Create;
end;


{ ** Collected ColorBoxChangeListener
  ** Saves the color of the snake and redraws the preview snake }
procedure TWindow.ColorBoxChange(Sender: TObject);
var
  f: TFile;
begin
  DrawPreviewSnake(PreviewSnake);
  f := GetTFile;
  f.SnakeColor := Settings.SnakeColor;
  Write(Storage, f);
  Seek(Storage, 0);
end;


{ ** ColorBoxChangeListener for the color of the head }
procedure TWindow.HeadColorBoxChange(Sender: TObject);
var
  Color: TSnakeColor;
begin
  Color := Settings.SnakeColor;
  Color.Head := HeadColorBox.Selected;
  Settings.SnakeColor := Color;
  ColorBoxChange(Sender);
end;


{ ** ColorBoxChangeListener for the primary color of the Snake}
procedure TWindow.PrimaryColorBoxChange(Sender: TObject);
var
  Color: TSnakeColor;
begin
  Color := Settings.SnakeColor;
  Color.Primary := PrimaryColorBox.Selected;
  Settings.SnakeColor := Color;
  ColorBoxChange(Sender);
end;


{ ** ColorBoxChangeListener for the secondary color of the Snake }
procedure TWindow.SecondaryColorBoxChange(Sender: TObject);
var
  Color: TSnakeColor;
begin
  Color := Settings.SnakeColor;
  Color.Secondary := SecondaryColorBox.Selected;
  Settings.SnakeColor := Color;
  ColorBoxChange(Sender);
end;


{ ** TabControlChangeListener
  ** Checks which panel has to be displayed }
procedure TWindow.TabControlChange(Sender: TObject);
begin
  SnakeDesignPanel.Visible := False;
  HighscorePanel.Visible := False;
  BackgroundDesignPanel.Visible := False;
  HelpPanel.Visible := False;

  case TabControl.TabIndex of
    0: begin
      HighscorePanel.Visible := True;
    end;
    1: begin
      SnakeDesignPanel.Visible := True;
    end;
    2: begin
      BackgroundDesignPanel.Visible := True;
    end;
    3: begin
      HelpPanel.Visible := True;
    end;
  end;
end;


{ ** FormCloseListener
  ** Saves the data}
procedure TWindow.FormClose(Sender: TObject; var Action: TCloseAction);
var
  f: TFile;
begin
  f := GetTFile;
  f.PlayerName := Playername.Text;
  Write(Storage, f);
  Seek(Storage, 0);
  if Snake <> nil then begin
    Snake.EndGame(True);
  end;
  CloseFile(Storage);
end;


{ ** OnExitListener
  ** Updated the settings when the playername label is exit }
procedure TWindow.PlayernameExit(Sender: TObject);
begin
  Settings.PlayerName := Playername.Text;
end;


{ ** ComboBoxChangeListener
  ** Updates the buttons to the selected background type to choose a background }
procedure TWindow.BackgroundTypeChange(Sender: TObject);
var
  i: Integer;
  Bitmap: TBitmap;
begin
  for i := 0 to Length(SelectBackgroundButtons) - 1 do begin
    if Assigned(SelectBackgroundButtons[i]) then begin
      SelectBackgroundButtons[i].Hide;
    end;
  end;

  case BackgroundType.ItemIndex of
    0: begin
      for i := 0 to GrassImageList.Count - 1 do begin
        SelectBackgroundButtons[i] := TBitBtn.Create(self);
        SelectBackgroundButtons[i].Parent := BackgroundDesignPanel;
        SelectBackgroundButtons[i].Width := 40;
        SelectBackgroundButtons[i].Height := 40;
        SelectBackgroundButtons[i].Top := 85;
        SelectBackgroundButtons[i].Left := i * 50 + 50;
        SelectBackgroundButtons[i].Hint := IntToStr(i);
        SelectBackgroundButtons[i].OnClick := OnBitBtnClick;

        Bitmap := TBitmap.Create;
        Bitmap.PixelFormat := pf32bit;
        GrassImageList.GetBitmap(i, Bitmap);
        SelectBackgroundButtons[i].Glyph.Assign(Bitmap);
        SelectBackgroundButtons[i].Glyph.TransparentColor := clNone;
      end;
    end;
    1: begin
      for i := 0 to SandImageList.Count - 1 do begin
        SelectBackgroundButtons[i] := TBitBtn.Create(self);
        SelectBackgroundButtons[i].Parent := BackgroundDesignPanel;
        SelectBackgroundButtons[i].Width := 40;
        SelectBackgroundButtons[i].Height := 40;
        SelectBackgroundButtons[i].Top := 85;
        SelectBackgroundButtons[i].Left := i * 50 + 50;
        SelectBackgroundButtons[i].Hint := IntToStr(i);
        SelectBackgroundButtons[i].OnClick := OnBitBtnClick;

        Bitmap := TBitmap.Create;
        Bitmap.PixelFormat := pf32bit;
        SandImageList.GetBitmap(i, Bitmap);
        SelectBackgroundButtons[i].Glyph.Assign(Bitmap);
        SelectBackgroundButtons[i].Glyph.TransparentColor := clNone;
      end;
    end;
    2: begin
      for i := 0 to StoneImageList.Count - 1 do begin
        SelectBackgroundButtons[i] := TBitBtn.Create(self);
        SelectBackgroundButtons[i].Parent := BackgroundDesignPanel;
        SelectBackgroundButtons[i].Width := 40;
        SelectBackgroundButtons[i].Height := 40;
        SelectBackgroundButtons[i].Top := 85;
        SelectBackgroundButtons[i].Left := i * 50 + 50;
        SelectBackgroundButtons[i].Hint := IntToStr(i);
        SelectBackgroundButtons[i].OnClick := OnBitBtnClick;

        Bitmap := TBitmap.Create;
        Bitmap.PixelFormat := pf32bit;
        StoneImageList.GetBitmap(i, Bitmap);
        SelectBackgroundButtons[i].Glyph.Assign(Bitmap);
        SelectBackgroundButtons[i].Glyph.TransparentColor := clNone;
      end;
    end;
    3: begin
      for i := 0 to DirtImageList.Count - 1 do begin
        SelectBackgroundButtons[i] := TBitBtn.Create(self);
        SelectBackgroundButtons[i].Parent := BackgroundDesignPanel;
        SelectBackgroundButtons[i].Width := 40;
        SelectBackgroundButtons[i].Height := 40;
        SelectBackgroundButtons[i].Top := 85;
        SelectBackgroundButtons[i].Left := i * 50 + 50;
        SelectBackgroundButtons[i].Hint := IntToStr(i);
        SelectBackgroundButtons[i].OnClick := OnBitBtnClick;

        Bitmap := TBitmap.Create;
        Bitmap.PixelFormat := pf32bit;
        DirtImageList.GetBitmap(i, Bitmap);
        SelectBackgroundButtons[i].Glyph.Assign(Bitmap);
        SelectBackgroundButtons[i].Glyph.TransparentColor := clNone;
      end;
    end;
  end;
end;


{ ** BitButton OnClickListener
  ** Sets the chosen background }
procedure TWindow.OnBitBtnClick(Sender: TObject);
var
  Button: TBitBtn;
  f: TFile;
  Style: TBackgroundStyle;
begin
  Button := Sender as TBitBtn;
  SelectedBackgroundImage.Picture.Bitmap.Assign(Button.Glyph);

  case BackgroundType.ItemIndex of
    0: Style := Grass;
    1: Style := Sand;
    2: Style := Stone;
    3: Style := Dirt;
    else Style := Grass;
  end;

  Settings.Background.Style := Style;
  Settings.Background.Index := StrToInt(Button.Hint);

  f := GetTFile;
  f.Background.Style := Style;
  f.Background.Index := StrToInt(Button.Hint);
  Write(Storage, f);
  Seek(Storage, 0);
end;


{ ** Constructor of Snake
  ** Initializations for the Snake object,
  ** Creates and positions the background panels and other components,
  ** Creates and sets the body of the snake
  ** Sets an apple,
  ** Starts timer to move Snake}
constructor TSnake.Create;
var
  i, j: Integer;
  Image: TImage;
  InformationPanel: TPanel;
  PlayernameLabel, ScoreLabel: TLabel;
begin
  inherited;

  IsPaused := False;

  Direction := DirLeft;
  BackgroundPanel := TPanel.Create(Window);
  BackgroundPanel.Parent := Window;
  BackgroundPanel.Width := Window.Width;
  BackgroundPanel.Height := Window.Height;

  Playground := TPanel.Create(Window);
  Playground.Parent := BackgroundPanel;
  Playground.Height := BackgroundPanel.Height - 80;
  Playground.Width := BackgroundPanel.Width - 180;
  Playground.Top := BackgroundPanel.Height div 2 - Playground.Height div 2 - GetSystemMetrics(SM_CYCAPTION);
  Playground.Left := 40;

  InformationPanel := TPanel.Create(Window);
  InformationPanel.Parent := BackgroundPanel;
  InformationPanel.Height := BackgroundPanel.Height;
  InformationPanel.Width := BackgroundPanel.Width - Playground.Width - Playground.Left;
  InformationPanel.Left := Playground.Left + Playground.Width;
  InformationPanel.BorderStyle := bsSingle;
  InformationPanel.Color := clWhite;

  PlayernameLabel := TLabel.Create(Window);
  PlayernameLabel.Parent := InformationPanel;
  PlayernameLabel.Caption := Settings.PlayerName;
  PlayernameLabel.Top := 50;
  PlayernameLabel.Left := InformationPanel.Width div 2 - PlayernameLabel.Width div 2;

  ScoreLabel := TLabel.Create(Window);
  ScoreLabel.Parent := InformationPanel;
  ScoreLabel.Caption := 'Punktzahl:';
  ScoreLabel.Top := 100;
  ScoreLabel.Left := InformationPanel.Width div 2 - ScoreLabel.Width div 2;
  ScoreLabel.Font.Size := 10;

  ScoreCounterLabel := TLabel.Create(Window);
  ScoreCounterLabel.Parent := InformationPanel;
  ScoreCounterLabel.Caption := '0';
  ScoreCounterLabel.Top := ScoreLabel.Top + ScoreLabel.Height + 3;
  ScoreCounterLabel.Left := InformationPanel.Width div 2 - ScoreCounterLabel.Width div 2;
  ScoreCounterLabel.Font.Size := 10;

  HighestScoreLabel := TLabel.Create(Window);
  HighestScoreLabel.Parent := InformationPanel;
  HighestScoreLabel.Caption := Concat('Highscore: ', IntToStr(HighScores[1].Score));
  HighestScoreLabel.Left := InformationPanel.Width div 2 - HighestScoreLabel.Width div 2;
  HighestScoreLabel.Top := ScoreCounterLabel.Top + ScoreCounterLabel.Height + 10;
  HighestScoreLabel.Font.Size := 10;

  PauseButton := TButton.Create(Window);
  PauseButton.Caption := 'Pause';
  PauseButton.Parent := InformationPanel;
  PauseButton.Width := InformationPanel.Width div 3 * 2;
  PauseButton.Top := InformationPanel.Height div 4 * 3;
  PauseButton.Left := InformationPanel.Width div 2 - PauseButton.Width div 2;
  PauseButton.OnClick := OnPauseButtonClick;
  PauseButton.TabStop := False;

  EndGameButton := TButton.Create(Window);
  EndGameButton.Caption := 'Menü';
  EndGameButton.Parent := InformationPanel;
  EndGameButton.Width := InformationPanel.Width div 3 * 2;
  EndGameButton.Top := PauseButton.Top + PauseButton.Height + 10;
  EndGameButton.Left := InformationPanel.Width div 2 - EndGameButton.Width div 2;
  EndGameButton.OnClick := OnEndGameButtonClick;
  EndGameButton.TabStop := False;

  Score := 0;

  for i := 0 to Playground.Height div SnakeWidth do begin
    for j := 0 to Playground.Width div SnakeWidth do begin
      Image := TImage.Create(Window);
      Image.Picture.Bitmap.Assign(GetBackgroundBitmap(Settings.Background.Index));
      Image.Top := i * SnakeWidth;
      Image.Left := j * SnakeWidth;
      Image.Parent := Playground;
    end;
  end;

  SetLength(Body, 2);
  for i := 1 downto 0 do begin
    Body[i] := TShape.Create(Window);
    Body[i].Parent := Playground;
    Body[i].Width := SnakeWidth;
    Body[i].Height := SnakeWidth;
  end;

  Body[0].Shape := stRoundSquare;
  Body[0].Brush.Color := Settings.SnakeColor.Head;
  Body[0].Pen.Color := Settings.SnakeColor.Head;

  SetCoordinates(Random(20) + 10, Random(5) + 5, Body[0]);

  Body[1].Left := Body[0].Left + SnakeWidth;
  Body[1].Top := Body[0].Top;
  Body[1].Brush.Color := Settings.SnakeColor.Primary;
  Body[1].Pen.Color := Settings.SnakeColor.Secondary;

  Timer := TTimer.Create(Window);
  Timer.Interval := Speed;
  Timer.Enabled := True;
  Timer.OnTimer := OnMove;

  RandomItemDespawnTimer := TTimer.Create(Window);
  RandomItemDespawnTimer.Enabled := False;
  RandomItemDespawnTimer.OnTimer := DespawnRandomItem;

  SetApple;
end;


{ ** Sets the coordinates of "Shape" }
procedure TSnake.SetCoordinates(cdX, cdY: Integer; var Shape: TShape);
begin
  Shape.Left := SnakeWidth * cdX;
  Shape.Top := SnakeWidth * cdY;
end;


{ ** Sets the coordinates of "Image" }
procedure TSnake.SetCoordinates(cdX, cdY: Integer; var Image: TImage);
begin
  Image.Left := SnakeWidth * cdX;
  Image.Top := SnakeWidth * cdY;
end;


{ ** OnTimerListener for "Timer"
  ** Moves the Snake,
  ** Checks if next coordinate is a wall or the Snake itself and ends the game iff applicable,
  ** Eats apples and random items }
procedure TSnake.OnMove(Sender: TObject);
var
  i: Integer;
begin
  if Not WillCrash then begin
    for i := Length(Body) - 1 downto 1 do begin
      Body[i].Left := Body[i - 1].Left;
      Body[i].Top := Body[i - 1].Top;
    end;
    case Direction of
      DirUp: Body[0].Top := Body[0].Top - SnakeWidth;
      DirDown: Body[0].Top := Body[0].Top + SnakeWidth;
      DirLeft: Body[0].Left := Body[0].Left - SnakeWidth;
      DirRight: Body[0].Left := Body[0].Left + SnakeWidth;
    end;
    IsKeyListenerBlocked := False;
    if (Body[0].Top = Apple.Top) AND (Body[0].Left = Apple.Left) then begin
      EatApple;
    end;
    if (RandomItem <> nil) AND (Body[0].Top = RandomItem.Top) AND (Body[0].Left = RandomItem.Left) then begin
      EatRandomItem;
    end;

    if (not RandomItemDespawnTimer.Enabled) AND (Random(RandomItemSpawnChance) = 1) then begin
      SetRandomItem;
    end;
  end else begin
    EndGame(False);
  end;
end;


{ ** Return true if next coordinate is a wall or the Snake itself }
function TSnake.WillCrash: boolean;
var
  i: Integer;
begin
  Result := False;
  case Direction of
    DirUp: begin
      if Body[0].Top - SnakeWidth < 0 then begin
        Result := True;
      end else begin
        for i := 1 to Length(Body) - 1 do begin
          if (Body[i].Top = Body[0].Top - SnakeWidth) AND (Body[i].Left = Body[0].Left) then begin
            Result := True;
            Break;
          end;
        end;

        for i := 0 to Length(Barriers) - 1 do begin
          if (Body[0].Top - SnakeWidth = Barriers[i].y) AND (Body[0].Left = Barriers[i].x) then begin
            Result := True;
            Break;
          end;
        end;
      end;
    end;
    DirDown: begin
      if Body[0].Top + SnakeWidth >= Playground.Height then begin
        Result := True;
      end else begin
        for i := 1 to Length(Body) - 1 do begin
          if (Body[i].Top = Body[0].Top + SnakeWidth) AND (Body[i].Left = Body[0].Left) then begin
            Result := True;
            Break;
          end;
        end;

        for i := 0 to Length(Barriers) - 1 do begin
          if (Body[0].Top + SnakeWidth = Barriers[i].y) AND (Body[0].Left = Barriers[i].x) then begin
            Result := True;
            Break;
          end;
        end;
      end;
    end;
    DirLeft: begin
      if Body[0].Left - SnakeWidth < 0 then begin
        Result := True;
      end else begin
        for i := 1 to Length(Body) - 1 do begin
          if (Body[i].Top = Body[0].Top) AND (Body[i].Left = Body[0].Left - SnakeWidth) then begin
            Result := True;
            Break;
          end;
        end;

        for i := 0 to Length(Barriers) - 1 do begin
          if (Body[0].Top = Barriers[i].y) AND (Body[0].Left - SnakeWidth = Barriers[i].x) then begin
            Result := True;
            Break;
          end;
        end;
      end;
    end;
    DirRight: begin
      if Body[0].Left + SnakeWidth >= Playground.Width then begin
        Result := True;
      end else begin
        for i := 1 to Length(Body) - 1 do begin
          if (Body[i].Top = Body[0].Top) AND (Body[i].Left = Body[0].Left + SnakeWidth) then begin
            Result := True;
            Break;
          end;
        end;

        for i := 0 to Length(Barriers) - 1 do begin
          if (Body[0].Top = Barriers[i].y) AND (Body[0].Left + SnakeWidth = Barriers[i].x) then begin
            Result := True;
            Break;
          end;
        end;
      end;
    end;
  end;

end;


{ ** KeyListener
  ** Sets the direction of the Snake when WASD or arrow keys are pressed,
  ** Prevents current 180° movements,
  ** Makes it necessary to press the key at the right moment and prevents wild clicking }
procedure TWindow.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(Snake) AND (Not Snake.IsKeyListenerBlocked) AND (Not Snake.isPaused) then begin
    case Key of
      37, 65: begin
        if Snake.Direction <> DirRight then begin
          Snake.Direction := DirLeft;
        end;
      end;
      38, 87: begin
        if Snake.Direction <> DirDown then begin
          Snake.Direction := DirUp;
        end;
      end;
      39, 68: begin
        if Snake.Direction <> DirLeft then begin
          Snake.Direction := DirRight;
        end;
      end;
      40, 83: begin
        if Snake.Direction <> DirUp then begin
          Snake.Direction := DirDown;
        end;
      end;
    end;
    Snake.IsKeyListenerBlocked := True;
  end;
end;


{ ** Ends the game, stops the Snake's movement and possibly saves highscores
  ** Boolean to check, if MessageSender can be called or window will be closed }
procedure TSnake.EndGame(CallerClosesPlayground: Boolean);
var
  i, j: Integer;
  f: TFile;
begin
  Crashed := True;
  Timer.Enabled := False;
  RandomItemDespawnTimer.Enabled := False;
  PauseButton.Visible := False;

  MessageSender := TMessageSender.Create;
  MessageSender.Send('Game Over!', Playground.Width div 2 - 55, Playground.Height div 2 + 10, 200000);
  for i := 1 to 10 do begin
    if Score > HighScores[i].Score then begin
      HighScores[i].Score := Score;
      HighScores[i].Name := Settings.PlayerName;

      if not CallerClosesPlayground then begin
        MessageSender := TMessageSender.Create;
        MessageSender.Send('Highscore!', Playground.Width div 2 - 49, Playground.Height div 2 - 10, 150000);
      end;

      f := GetTFile;
      for j := 9 downto i do begin
        f.HighScore[j + 1].Score := f.HighScore[j].Score;
        f.HighScore[j + 1].Name := f.HighScore[j].Name;
      end;
      f.HighScore[i].Score := Score;
      f.HighScore[i].Name := Settings.PlayerName;
      Write(Storage, f);
      Seek(Storage, 0);
      Score := 0;
      Break;
    end;
  end;
end;


{ ** Sets an apple on the playground (not on the Snake) }
procedure TSnake.SetApple;
var
  Bitmap: TBitmap;
  CordX, CordY: Integer;
begin
  repeat
    CordX := Random(Playground.Width div SnakeWidth);
    CordY := Random(Playground.Height div SnakeWidth);
  until not WouldAppleBeOnSnake(CordX, CordY);
  Bitmap := TBitmap.Create;
  Apple := TImage.Create(Window);

  Apple.Parent := Playground;
  Apple.Transparent := True;


  Window.ItemList.GetBitmap(0, Bitmap);

  Apple.Picture.Bitmap.Assign(Bitmap);
  Apple.Width := SnakeWidth;
  Apple.Height := SnakeWidth;
  SetCoordinates(CordX, CordY, Apple);
end;


{ ** Removes the existing apple, increases the score and the speed,
  ** enlengths the Snake }
procedure TSnake.EatApple;
var
  SnakeShape: TShape;
begin

  Apple.Left := 20000;
  Score := Score + 1;
  ScoreCounterLabel.Caption := IntToStr(Score);
  Apple.Destroy;

  SetLength(Body, Length(Body) + 1);
  SnakeShape := TShape.Create(Window);
  SnakeShape.Parent := Playground;
  SnakeShape.Width := SnakeWidth;
  SnakeShape.Height := SnakeWidth;
  SnakeShape.Left := -100;
  if Length(Body) mod 2 = 0 then begin
    SnakeShape.Brush.Color := Settings.SnakeColor.Primary;
    SnakeShape.Pen.Color := Settings.SnakeColor.Secondary;
  end else begin
    SnakeShape.Brush.Color := Settings.SnakeColor.Secondary;
    SnakeShape.Pen.Color := Settings.SnakeColor.Primary;
  end;

  if Score > HighScores[1].Score then begin
    HighestScoreLabel.Caption := Concat('Highscore: ', IntToStr(Score));
  end;


  Body[Length(Body) - 1] := SnakeShape;

  IncreaseSpeed;

  MessageSender := TMessageSender.Create;
  MessageSender.Send('+1');

  SetApple;
end;


{ ** Checks if the coordinates cdX and cdY would equal on of the Snake's body shapes }
function TSnake.WouldAppleBeOnSnake(cdX, cdY: Integer): boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(Body) - 1 do begin
    if (Body[i].Left = cdX * SnakeWidth) AND (Body[i].Top = cdY * SnakeWidth) then begin
      Result := True;
      Break;
    end;
  end;
end;


{ ** Increase the movement speed depending on the score }
procedure TSnake.IncreaseSpeed;
begin
  if Score < 10 then begin
    Timer.Interval := Timer.Interval - 10;
  end else if Score < 20 then begin
    Timer.Interval := Timer.Interval - 6;
  end else if Score < 30 then begin
    Timer.Interval := Timer.Interval - 5;
  end else if Score < 40 then begin
    Timer.Interval := Timer.Interval - 4;
  end else if Score < 50 then begin
    Timer.Interval := Timer.Interval - 3;
  end else begin
    Timer.Interval := Timer.Interval - 2;
  end;
end;


{ ** OnButtonClickListener closes the game }
procedure TWindow.CloseButtonClick(Sender: TObject);
begin
  Application.Terminate;
end;


{ ** OnButtonClickListener
  ** Ends the game and calls the title screen }
procedure TSnake.OnEndGameButtonClick(Sender: TObject);
begin
  EndGame(True);
  Snake.BackgroundPanel.Hide;
  Window.TitleScreen.Show;
  Window.OnCreate(Sender);
  Window.Caption := 'Snake - Menü';
  Self.Destroy;
end;


{ ** OnButtonClickListener pauses the game }
procedure TSnake.OnPauseButtonClick(Sender: TObject);
begin                          
  Timer.Enabled := not Timer.Enabled;
  if IsRandomItemSpawned then begin
    RandomItemDespawnTimer.Enabled := not RandomItemDespawnTimer.Enabled;
  end;
  IsPaused := not IsPaused;
  Window.ActiveControl := nil;
end;


{ ** Sets a random item of TItemType on the playground (not on the Snake)
  ** and sets the time until it will despawn }
procedure TSnake.SetRandomItem;
var
  RandomNumber: Integer;
  Bitmap: TBitmap;
  CordX, CordY: Integer;
  LightningCordX, LightningCordY: Integer;
begin
  RandomNumber := Random(6);

  IsRandomItemSpawned := True;

  repeat
    CordX := Random(Playground.Width div SnakeWidth);
    CordY := Random(Playground.Height div SnakeWidth);
  until not WouldAppleBeOnSnake(CordX, CordY);

  RandomItem := TImage.Create(Window);
  RandomItem.Parent := Playground;

  Bitmap := TBitmap.Create;
  Window.ItemList.GetBitmap(RandomNumber, Bitmap);

  RandomItem.Picture.Bitmap.Assign(Bitmap);
  RandomItem.Width := SnakeWidth;
  RandomItem.Height := SnakeWidth;
  RandomItem.Transparent := True;
  SetCoordinates(CordX, CordY, RandomItem);

  RandomItemDespawnTimer.Enabled := True;

  case RandomNumber of
    0: begin
      RandomItemType := NormalApple;
      RandomItemDespawnTimer.Interval := 1000 * (20 + Random(25));
    end;
    1: begin
      RandomItemType := GoldenApple;
      RandomItemDespawnTimer.Interval := 1000 * (10 + Random(5));
    end;
    2: begin
      RandomItemType := Lightning;
      RandomItemDespawnTimer.Interval := 1000 * (15 + Random(5));
      repeat
        LightningCordX := Apple.Left div SnakeWidth;
        LightningCordY := Apple.Top div SnakeWidth;

        if Random(2) = 0 then begin
          LightningCordX := LightningCordX + 1;
        end else if Random(2) = 0 then begin
          LightningCordX := LightningCordX - 1;
        end;
        if Random(2) = 0 then begin
          LightningCordY := LightningCordY + 1;
        end else if Random(2) = 0 then begin
          LightningCordY := LightningCordY - 1;
        end;
      until not WouldAppleBeOnSnake(LightningCordX, LightningCordY);
      SetCoordinates(LightningCordX, LightningCordY, RandomItem);
    end;
    3: begin
      RandomItemType := PoisonousPotato;
      RandomItemDespawnTimer.Interval := 1000 * (15 + Random(15));
    end;
    4: begin
      RandomItemType := Potato;
      RandomItemDespawnTimer.Interval := 1000 * (10 + Random(15));
    end;
    5: begin
      RandomItemType := Snail;
      RandomItemDespawnTimer.Interval := 1000 * (10 + Random(15));
    end;
  end;

end;


{ ** OnTimerListener removes the random item}
procedure TSnake.DespawnRandomItem(Sender: TObject);
begin
  RandomItem.Left := 20000;
  RandomItem.Destroy;
  RandomItemDespawnTimer.Enabled := False;
  IsRandomItemSpawned := False;
end;


{ ** Removes the random item and handles the corresponding score and length of the Snake}
procedure TSnake.EatRandomItem;
var
  NewLength: Integer;
  i: Integer;
  SnakeShape: TShape;
begin
  IsRandomItemSpawned := False;

  RandomItemDespawnTimer.Enabled := False;
  RandomItem.Left := 20000;
  RandomItem.Destroy;

  MessageSender := TMessageSender.Create;

  NewLength := 1;

  case RandomItemType of
    NormalApple: begin
      Score := Score + 1;
      NewLength := 1;
      IncreaseSpeed;
      MessageSender.Send('+1');
    end;
    GoldenApple: begin
      Score := Score + 2;
      NewLength := -2;
      MessageSender.Send('+2');
    end;
    Lightning: begin
      Score := Score + 3;
      NewLength := 1;
      Timer.Interval := Timer.Interval - 25;
      MessageSender.Send('+3');
    end;
    Snail: begin
      Score := Score + 1;
      NewLength := 2;
      if Timer.Interval < 50 then begin
        Timer.Interval := Timer.Interval + 30;
      end else if Timer.Interval < 100 then begin
        Timer.Interval := Timer.Interval + 21;
      end else if Timer.Interval < 150 then begin
        Timer.Interval := Timer.Interval + 17;
      end else if Timer.Interval < 200 then begin
        Timer.Interval := Timer.Interval + 15;
      end else if Timer.Interval < 250 then begin
        Timer.Interval := Timer.Interval + 10;
      end else begin
        Timer.Interval := Timer.Interval + 5;
      end;
      MessageSender.Send('+1');
    end;
    Potato: begin
      Score := Score + 1;
      NewLength := -1;
      IncreaseSpeed;
      MessageSender.Send('+1');
    end;
    PoisonousPotato: begin
      Score := Score - 2;
      NewLength := 2;
      IncreaseSpeed;
      MessageSender.Send('-2');
    end;
  end;
  if Score < 0 then begin
    Score := 0;
  end;
  ScoreCounterLabel.Caption := IntToStr(Score);

  for i := 1 to NewLength do begin
    SnakeShape := TShape.Create(Window);
    SnakeShape.Parent := Playground;
    SnakeShape.Width := SnakeWidth;
    SnakeShape.Height := SnakeWidth;
    SnakeShape.Left := -100;
    if Length(Body) mod 2 = 1 then begin
      SnakeShape.Brush.Color := Settings.SnakeColor.Primary;
      SnakeShape.Pen.Color := Settings.SnakeColor.Secondary;
    end else begin
      SnakeShape.Brush.Color := Settings.SnakeColor.Secondary;
      SnakeShape.Pen.Color := Settings.SnakeColor.Primary;
    end;
    SetLength(Body, Length(Body) + 1);
    Body[Length(Body) - 1] := SnakeShape;
  end;

  for i := -1 downto NewLength do begin
    if Length(Body) - 1 > -NewLength then begin
      TBarrier.CreateBarrier(Body[Length(Body) - 1].Left, Body[Length(Body) - 1].Top, (Random(121) + 60) * 1000, Self);
      Body[Length(Body) - 1].Destroy;
      SetLength(Body, Length(Body) - 1);
    end;
  end;


  if Score > HighScores[1].Score then begin
    HighestScoreLabel.Caption := Concat('Highscore: ', IntToStr(Score));
  end else begin
    HighestScoreLabel.Caption := Concat('Highscore: ', IntToStr(HighScores[1].Score));
  end;
end;


{ ** Sends a message relative to the Snake's head for 1 second }
procedure TMessageSender.Send(MSG: String);
var
  CordX, CordY: Integer;
begin
  if Snake.Body[1].Top > Snake.Playground.Height div 2 then begin
    CordY := Snake.Body[1].Top - 25;
  end else begin
    CordY := Snake.Body[1].Top + 25;
  end;

  if Snake.Body[1].Left > Snake.Playground.Width div 2 then begin
    CordX := Snake.Body[1].Left - 25;
  end else begin
    CordX := Snake.Body[1].Left + 25;
  end;

  Send(MSG, CordX, CordY, 1000);
end;


{ ** Sends a message to the coordinates of the playground in px with a custom Length }
procedure TMessageSender.Send(MSG: String; CordX, CordY, Length: Integer);
begin
  Timer := TTimer.Create(Window);
  Timer.Interval := Length;
  Timer.OnTimer := OnTimer;

  TextField.Caption := MSG;

  TextField := TLabel.Create(Window);
  TextField.Caption := MSG;
  TextField.Parent := Snake.Playground;
  TextField.Transparent := True;
  TextField.Font.Style := [fsBold];
  TextField.Font.Size := 15;
  TextField.Left := CordX;
  TextField.Top := CordY;
end;


{ ** OnTimerListener removes the sent messages }
procedure TMessageSender.OnTimer(Sender: TObject);
begin
  TextField.Destroy;
  Timer.Enabled := False;
end;


{ ** Constructor
  ** Creates barriers on the playground of Snake with the coordinates }
constructor TBarrier.CreateBarrier(CordX, CordY, Time: Integer; var Snake: TSnake);
var
  Bitmap: TBitmap;
begin
  inherited Create;

  Self.Snake := Snake;

  Timer := TTimer.Create(Window);
  Timer.Interval := Time;
  Timer.Enabled := True;
  Timer.OnTimer := DestroyBarrier;

  PauseChecker := TTimer.Create(Window);
  PauseChecker.OnTimer := CheckForPause;
  PauseChecker.Interval := 10000;

  Bitmap := TBitmap.Create;
  Window.BarrierList.GetBitmap(Random(Window.BarrierList.Count), Bitmap);
  Image := TImage.Create(Window);
  Image.Picture.Bitmap.Assign(Bitmap);
  Image.Parent := Snake.Playground;
  Image.Left := CordX;
  Image.Top := CordY;

  Coordinates.x := CordX;
  Coordinates.y := CordY;

  SetLength(Snake.Barriers, Length(Snake.Barriers) + 1);
  Snake.Barriers[Length(Snake.Barriers) -1] := Coordinates;
end;


{ ** OnTimerListener removes barriers }
procedure TBarrier.DestroyBarrier(Sender: TObject);
var
  i: Integer;
begin
  if (not Snake.Crashed) OR (Snake = nil) then begin
    Timer.Enabled := False;
    PauseChecker.Enabled := False;
    for i := 0 to Length(Snake.Barriers) - 1 do begin
      if (Snake.Barriers[i].x = Coordinates.x) AND (Snake.Barriers[i].y = Coordinates.y) then begin
        Snake.Barriers[i].x := 20000;
        Snake.Barriers[i].y := 20000;
        Break;
      end;
    end;
  Image.Destroy;
  Self.Destroy;
  end;
end;


{ ** OnTimerListener checks if Snake game is paused and disables TBarrier.Timer then }
procedure TBarrier.CheckForPause(Sender: TObject);
begin
  Timer.Enabled := not Snake.IsPaused;
end;

end.
