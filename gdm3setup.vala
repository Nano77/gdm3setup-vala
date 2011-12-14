// -*- mode: vala; vala-indent-level: 4; indent-tabs-mode: nil -*-
using Gtk;
using GLib;

[DBus (name = "apps.nano77.gdm3setup")]
interface GDM3SETUP : Object {
    public abstract string SetUI (string name,string value) throws IOError;
    public abstract string[] GetUI () throws IOError;
    public abstract void SetAutoLogin (bool autologin, string username, bool timed, int timed_time) throws IOError;
    public abstract string[] GetAutoLogin () throws IOError; 
    public abstract void StopDaemon () throws IOError;
}

class WallpaperChooserClass : Gtk.HBox {
    private Button button;
    private Label label;
    private Image image;
    private Separator separator;
    private HBox Box;
    private string Filename;
    private FileChooserDialog fileChooserDialog;
    private FileFilter filter;

    public signal void file_changed ();

    public WallpaperChooserClass() {
        this.button = new Button();
        this.add(this.button);
        this.label = new Label(_("(None)"));
        this.image = new Gtk.Image();
        this.image.set_from_icon_name("fileopen",Gtk.IconSize.SMALL_TOOLBAR);
        this.separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        this.Box = new Gtk.HBox(false,0);
        this.button.add(this.Box);
        this.Box.pack_start(this.label,false,false,2);
        this.Box.pack_end(this.image,false,false,2);
        this.Box.pack_end(this.separator,false,false,2);
        this.filter = new Gtk.FileFilter();
        this.filter.add_pixbuf_formats();
        this.filter.set_filter_name("Image");

        this.Filename = "";
        this.button.clicked.connect(this._Clicked);
    }

    public string Get_Filename() {
        return this.Filename;
    }

    public void Set_Filename(string filename) {
        this.Filename = filename;
        this.label.set_label( GLib.Path.get_basename(filename));
        this.file_changed();
    }

    void _Clicked() {
        this.fileChooserDialog = new FileChooserDialog(null,null,
                                      FileChooserAction.OPEN,
                                      Stock.CANCEL, ResponseType.CANCEL,
                                      Stock.OPEN, ResponseType.ACCEPT);
        this.fileChooserDialog.add_filter(filter);
        this.fileChooserDialog.set_filename(this.Filename);
        this.fileChooserDialog.add_shortcut_folder("/usr/share/backgrounds");
        int result = fileChooserDialog.run();
        if (result==ResponseType.ACCEPT) {
            this.Filename = fileChooserDialog.get_filename();
            this.label.set_label(GLib.Path.get_basename(this.Filename));
            fileChooserDialog.destroy();
            this.file_changed();
        }
        else
            fileChooserDialog.destroy();

    }

}


ComboBoxText ComboBox_gtk;
ComboBoxText ComboBox_shell;
WallpaperChooserClass WallpaperChooser;
FontButton FontButton;
ComboBoxText ComboBox_icon;
ComboBoxText ComboBox_cursor;
Entry Entry_logo;
CheckButton CheckButton_banner;
Entry Entry_banner_text;
CheckButton CheckButton_user;
CheckButton CheckButton_restart;

Window window2;
CheckButton CheckButton_AutoLogin;
HBox HBox_username;
Entry Entry_username;
HBox HBox_Delay;
CheckButton CheckButton_Delay;
SpinButton SpinButton_Delay;

HBox HBox_AutoLogin_Apply;

GDM3SETUP gdm3setup;

string GTK3_THEME;
string SHELL_THEME;
string FONT_NAME;
string ICON_THEME;
string CURSOR_THEME;
string LOGO_ICON;
string BKG;
string WALLPAPER;
bool USER_LIST;
bool MENU_BTN;
bool BANNER;
string BANNER_TEXT;

void window_close() {
    try {
        gdm3setup.StopDaemon();
    }
    catch {
        stderr.printf("");
    }
    Gtk.main_quit();
}

void load_gtk3_list() {
    string name,file;
    var d = Dir.open("/usr/share/themes/");
    while ((name = d.read_name()) != null) {
        file = "/usr/share/themes/%s/gtk-3.0/".printf(name);
        if (FileUtils.test (file,FileTest.IS_DIR)) {
            ComboBox_gtk.append_text(name);
        }
    }
}

void load_shell_list() {
    string name,file,file2;
    var d = Dir.open("/usr/share/themes/");
    ComboBox_shell.append_text("Adwaita");
    while ((name = d.read_name()) != null) {
        file = "/usr/share/themes/%s/gnome-shell/".printf(name);
        if (FileUtils.test (file,FileTest.IS_DIR)) {
            file2 = "/usr/share/themes/%s/gnome-shell/gdm.css".printf(name);
            if (FileUtils.test (file2,FileTest.EXISTS)) {
                ComboBox_shell.append_text(name);
            }
        }
    }
}

void load_icon_list() {
    string name,file;
    var d = Dir.open("/usr/share/icons/");
    while ((name = d.read_name()) != null) {
        file = "/usr/share/icons/%s/".printf(name);
        if (FileUtils.test (file,FileTest.IS_DIR)) {
            file = "/usr/share/icons/%s/cursors/".printf(name);
            if (FileUtils.test (file,FileTest.IS_DIR))
                ComboBox_cursor.append_text(name);
            else 
                ComboBox_icon.append_text(name);
        }
    }
}

string get_setting(string name,string[] data) {
    int i;
    string value="";
    for (i=0;i<data.length;i++) {
        string line = data[i].replace("\n","");
        if (line.length>name.length) {
            if (line[0:name.length+1] == name+"=") {
                value = line[name.length+1:line.length];
                break;
            }
        }
    }
    return value;
}

string  unquote(string value) {
    string val;
	if ( value[0:1] == "'"  && value[value.length-1:value.length] == "'")
		val = value[1:value.length-1];
    else
        val = value;
	return val;
}

Gtk.TreeIter get_iter(Gtk.TreeModel model,string target) {
    TreeIter target_iter;
    TreeIter iter_test;
    model.get_iter_first(out iter_test);

    target_iter = iter_test;
    
    do {
        Value name;
        model.get_value(iter_test,0,out name);
        if ( "'"+name.get_string()+"'" == target ) {
            target_iter = iter_test;
            break;
        }
    }
    while (model.iter_next(ref iter_test));

    return target_iter;
}


bool set_gdm(string name,string value) {
    if (gdm3setup.SetUI(name,value)=="OK" )
        return true;
    else
        return false;
}

void get_gdm() {
    string[] settings = gdm3setup.GetUI();

    GTK3_THEME = get_setting("GTK",settings);
    SHELL_THEME = get_setting("SHELL",settings);
    FONT_NAME = unquote(get_setting("FONT",settings));
    ICON_THEME = get_setting("ICON",settings);
    CURSOR_THEME = get_setting("CURSOR",settings);
    BKG = get_setting("BKG",settings);
    WALLPAPER = BKG[8:BKG.length-1];
    LOGO_ICON = get_setting("LOGO",settings);
    USER_LIST = bool.parse(get_setting("USER_LIST",settings));
    MENU_BTN = bool.parse( get_setting("BTN" ,settings));
    BANNER = bool.parse(get_setting("BANNER",settings));
    BANNER_TEXT = get_setting("BANNER_TEXT",settings);

    ComboBox_gtk.set_active_iter(get_iter(ComboBox_gtk.get_model(),GTK3_THEME));
    ComboBox_shell.set_active_iter(get_iter(ComboBox_shell.get_model(),SHELL_THEME));
    FontButton.set_font_name(FONT_NAME);
    WallpaperChooser.Set_Filename(WALLPAPER);
    ComboBox_icon.set_active_iter(get_iter(ComboBox_icon.get_model(),ICON_THEME));
    ComboBox_cursor.set_active_iter(get_iter(ComboBox_cursor.get_model(),CURSOR_THEME));
    Entry_logo.set_text(LOGO_ICON);
    CheckButton_banner.set_active(BANNER);
    Entry_banner_text.set_text(BANNER_TEXT);
    CheckButton_user.set_active(USER_LIST);
    CheckButton_restart.set_active(MENU_BTN);
    Entry_banner_text.set_sensitive(BANNER);

}

void gtk3_theme_changed() {
    string gtk_theme = ComboBox_gtk.get_active_text();
    if (gtk_theme!=unquote(GTK3_THEME)) {
        if (set_gdm("GTK_THEME",gtk_theme)) {
            GTK3_THEME = gtk_theme;
            stdout.printf("GTK3 Theme Changed : %s\n",GTK3_THEME);
        }
        else
            ComboBox_gtk.set_active_iter(get_iter(ComboBox_gtk.get_model(),GTK3_THEME));
    }
}

void shell_theme_changed() {
    string shell_theme = ComboBox_shell.get_active_text();
    if (shell_theme!=unquote(SHELL_THEME)) {
        if (set_gdm("SHELL_THEME",shell_theme)) {
            SHELL_THEME = shell_theme;
            stdout.printf("SHELL Theme Changed : %s\n",SHELL_THEME);
        }
        else
            ComboBox_shell.set_active_iter(get_iter(ComboBox_shell.get_model(),SHELL_THEME));
    }
}

void font_set() {
    string font_name = FontButton.get_font_name();
    if (FONT_NAME != font_name) { 
        if (set_gdm("FONT",font_name)) {
            FONT_NAME = font_name;
            stdout.printf("Font Changed : %s\n",font_name);
        }
        else
            FontButton.set_font_name(FONT_NAME);
    }
}

void wallpaper_filechanged() {
    string wallpaper = WallpaperChooser.Get_Filename();
    if (WALLPAPER != wallpaper) {
        if (set_gdm("WALLPAPER",wallpaper)) {
            WALLPAPER = wallpaper;
            stdout.printf("Wallpaper Changed : %s\n", WALLPAPER);
        }
        else
            WallpaperChooser.Set_Filename(WALLPAPER);
    }
}

void icon_theme_changed() {
    string icon_theme = ComboBox_icon.get_active_text();
    if (unquote(ICON_THEME) != icon_theme) {
        if (set_gdm("ICON_THEME",icon_theme)) {
            ICON_THEME = icon_theme;
            stdout.printf ("Icon Theme Changed : %s\n", ICON_THEME);
        }
        else
            ComboBox_icon.set_active_iter(get_iter(ComboBox_icon.get_model(),ICON_THEME));
    }
}

void cursor_theme_changed() {
    string cursor_theme = ComboBox_cursor.get_active_text();
    if (unquote(CURSOR_THEME) != cursor_theme) {
        if (set_gdm("CURSOR_THEME",cursor_theme)) {
            CURSOR_THEME = cursor_theme;
            stdout.printf ("Cursor Theme Changed : %s\n" , CURSOR_THEME);
        }
        else
            ComboBox_cursor.set_active_iter(get_iter(ComboBox_cursor.get_model(),CURSOR_THEME));
    }
}

void logo_icon_changed() {
    string logo_icon = Entry_logo.get_text();
    if (LOGO_ICON != logo_icon) {
        if (set_gdm("LOGO_ICON",logo_icon)) {
            LOGO_ICON = logo_icon;
            stdout.printf ("Logo Icon Changed : %s\n" , LOGO_ICON);
        }
        else
            Entry_logo.set_text(LOGO_ICON);
    }
}

void banner_toggled() {
    bool banner = CheckButton_banner.get_active();
    if (banner!=BANNER) {
        if (set_gdm("BANNER",banner.to_string())) {
            BANNER = banner;
            stdout.printf ("Banner Changed : %s\n",BANNER.to_string());

            if (BANNER)
                Entry_banner_text.set_sensitive(true);
            else
                Entry_banner_text.set_sensitive(false);
        }
        else
            CheckButton_banner.set_active(BANNER);
    }
}

void banner_text_changed() {
    string banner_text = Entry_banner_text.get_text();
    if (BANNER_TEXT!=banner_text) {
        if (set_gdm("BANNER_TEXT",banner_text)) {
            BANNER_TEXT = banner_text;
            stdout.printf ("Banner Text Changed : %s\n", BANNER_TEXT);
        }
        else
            Entry_banner_text.set_text(BANNER_TEXT);
    }
}

void user_list_toggled() {
    bool user_list = CheckButton_user.get_active();
    if (USER_LIST != user_list) {
        if (set_gdm("USER_LIST",user_list.to_string())) {
            USER_LIST = user_list;
            stdout.printf ("User List Changed : %s\n" ,USER_LIST.to_string());
         }
        else
            CheckButton_user.set_active(USER_LIST);
    }
}

void menu_btn_toggled() {
    bool menu_btn = CheckButton_restart.get_active();
    if (MENU_BTN != menu_btn) {
        if (set_gdm("MENU_BTN",menu_btn.to_string())) {
            MENU_BTN = menu_btn;
            stdout.printf ("Menu Btn Changed : %s\n",MENU_BTN.to_string());
        }
        else
            CheckButton_restart.set_active(MENU_BTN);
    }
}


void autologin_clicked() {
    window2.show_all();
}

bool Close_AutoLogin(Gdk.EventAny event) {
    window2.hide();
    return true;
}

void AutoLogin_toggled() {
    if (CheckButton_AutoLogin.get_active()) {
        HBox_username.set_sensitive(true);
        HBox_Delay.set_sensitive(true);
        }
    else {
        HBox_username.set_sensitive(false);
        HBox_Delay.set_sensitive(false);
    }

    if (Entry_username.get_text()!="" || CheckButton_AutoLogin.get_active()==false )
        HBox_AutoLogin_Apply.set_sensitive(true);
    else
        HBox_AutoLogin_Apply.set_sensitive(false);
}

void username_changed() {
    if (Entry_username.get_text()!="")
        HBox_AutoLogin_Apply.set_sensitive(true);
    else
        HBox_AutoLogin_Apply.set_sensitive(false);
}

void Delay_toggled() {
    if (CheckButton_Delay.get_active())
        SpinButton_Delay.set_sensitive(true);
    else
        SpinButton_Delay.set_sensitive(false);
}

void AutoLogin_Apply_clicked() {
    bool AUTOLOGIN = CheckButton_AutoLogin.get_active();
    bool TIMED = CheckButton_Delay.get_active();
    int TIMED_TIME = SpinButton_Delay.get_value_as_int();
    string USERNAME = Entry_username.get_text();

    gdm3setup.SetAutoLogin(AUTOLOGIN,USERNAME,TIMED,TIMED_TIME);

    window2.hide();
}

void get_autologin() {
    string[] Data = gdm3setup.GetAutoLogin();
    CheckButton_AutoLogin.set_active(bool.parse(Data[0]));
    Entry_username.set_text(Data[1]);
    CheckButton_Delay.set_active(bool.parse(Data[2]));
    SpinButton_Delay.set_value(double.parse(Data[3]));
}

int main (string[] args) {
    Gtk.init (ref args);

    GTK3_THEME = "";
    SHELL_THEME = "";
    FONT_NAME = "";
    ICON_THEME = "";
    CURSOR_THEME ="";
    WALLPAPER = "";
    LOGO_ICON = "";
    USER_LIST = false;
    MENU_BTN = false;
    BANNER = true;
    BANNER_TEXT = "";


    var window = new Window ();
    window.title = _("GDM3 Setup");
    window.border_width = 10;
    window.window_position = WindowPosition.CENTER;
    window.set_default_size (400, 300);
    window.set_resizable(false);
    window.set_icon_name("preferences-desktop-theme");
    window.destroy.connect(window_close);

    var VBox_Main = new Gtk.VBox (false, 4);
    window.add(VBox_Main);

    var HBox_Main = new Gtk.HBox (false, 16);
    VBox_Main.pack_start(HBox_Main, false, false, 0);

    var VBox_Left = new Gtk.VBox (true, 0);
    HBox_Main.pack_start(VBox_Left, false, false, 0);

    var VBox_Right = new Gtk.VBox (false, 0);
    HBox_Main.pack_start(VBox_Right, false, false, 0);

    var Label_gtk = new Gtk.Label(_("GTK3 theme"));
    Label_gtk.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_gtk, false, true, 0);

    ComboBox_gtk = new Gtk.ComboBoxText ();
    VBox_Right.pack_start(ComboBox_gtk, false, true, 0);

    var Label_shell = new Gtk.Label(_("Shell theme"));
    Label_shell.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_shell, false, true, 0);

    ComboBox_shell = new Gtk.ComboBoxText ();
    VBox_Right.pack_start(ComboBox_shell, false, true, 0);

    var Label_wallpaper = new Gtk.Label(_("Wallpaper"));
    Label_wallpaper.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_wallpaper, false, true, 0);

    WallpaperChooser = new WallpaperChooserClass();
    VBox_Right.pack_start(WallpaperChooser, false, true, 0);

    var Label_font = new Gtk.Label(_("Font"));
    Label_font.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_font, false, true, 0);

    FontButton = new Gtk.FontButton ();
    VBox_Right.pack_start(FontButton, false, true, 0);

    var Label_icon = new Gtk.Label(_("Icon theme"));
    Label_icon.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_icon, false, true, 0);

    ComboBox_icon = new Gtk.ComboBoxText ();
    VBox_Right.pack_start(ComboBox_icon, false, true, 0);

    var Label_cursor = new Gtk.Label(_("Cursor theme"));
    Label_cursor.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_cursor, false, true, 0);

    ComboBox_cursor = new  Gtk.ComboBoxText ();
    VBox_Right.pack_start(ComboBox_cursor, false, true, 0);

    var Label_logo = new Gtk.Label(_("Logo Icon"));
    Label_logo.set_alignment(0,0.5f);
    VBox_Left.pack_start(Label_logo, false, true, 0);

    Entry_logo = new Gtk.Entry();
    VBox_Right.pack_start(Entry_logo, false, true, 0);

    CheckButton_banner = new Gtk.CheckButton.with_label (_("Enable Banner"));
    VBox_Left.pack_start(CheckButton_banner, false, true, 0);

    Entry_banner_text = new Gtk.Entry();
    Entry_banner_text.set_sensitive(false);
    VBox_Right.pack_start(Entry_banner_text, false, true, 0);

    var HBox_user = new Gtk.HBox (true, 0);
    VBox_Main.pack_start(HBox_user, false, true, 0);

    CheckButton_user = new Gtk.CheckButton.with_label (_("Disable User List"));
    HBox_user.pack_start(CheckButton_user, false, true, 0);

    var HBox_restart = new Gtk.HBox (true, 0);
    VBox_Main.pack_start(HBox_restart, false, true, 0);

    CheckButton_restart = new Gtk.CheckButton.with_label (_("Disable Restart Buttons"));
    HBox_restart.pack_start(CheckButton_restart, false, true, 0);

    var HBox_autologin = new Gtk.HBox (false, 8);
    VBox_Main.pack_end(HBox_autologin, false, false, 0);

    var BTN_autologin = new Gtk.Button.with_label (_("AutoLogin"));
    BTN_autologin.clicked.connect(autologin_clicked);
    HBox_autologin.pack_start(BTN_autologin, false, false, 0);

    window2 = new Window ();
    window2.title = "GDM AutoLogin Setup";
    window2.border_width = 10;
    window2.window_position = WindowPosition.CENTER_ON_PARENT;
    window2.set_modal(true);
    window2.set_transient_for(window);
    window2.set_default_size (400, 300);
    window2.set_resizable(false);
    window2.set_icon_name("preferences-desktop-theme");
    window2.delete_event.connect(Close_AutoLogin);

    var VBoxMain_Autologin = new Gtk.VBox (false, 8);
    window2.add(VBoxMain_Autologin);

    CheckButton_AutoLogin = new Gtk.CheckButton.with_label(_("Enable Automatic Login"));
    CheckButton_AutoLogin.toggled.connect(AutoLogin_toggled);
    VBoxMain_Autologin.pack_start(CheckButton_AutoLogin, false, false, 0);

    HBox_username = new Gtk.HBox(false, 0);
    HBox_username.set_sensitive(false);
    VBoxMain_Autologin.pack_start(HBox_username, false, false, 0);

    var Label_username = new Gtk.Label(_("User Name"));
    Label_username.set_alignment(0,0.5f);
    HBox_username.pack_start(Label_username, false, false, 0);

    Entry_username = new Gtk.Entry();
    Entry_username.changed.connect(username_changed);
    HBox_username.pack_end(Entry_username, false, false, 0);

    HBox_Delay = new Gtk.HBox(false, 8);
    HBox_Delay.set_sensitive(false);
    VBoxMain_Autologin.pack_start(HBox_Delay, false, false, 0);

    CheckButton_Delay = new Gtk.CheckButton.with_label(_("Enable Delay before autologin"));
    CheckButton_Delay.toggled.connect(Delay_toggled);
    HBox_Delay.pack_start(CheckButton_Delay, false, false, 0);

    SpinButton_Delay = new Gtk.SpinButton.with_range(1,60,1);
    SpinButton_Delay.set_value(10);
    SpinButton_Delay.set_sensitive(false);
    HBox_Delay.pack_end(SpinButton_Delay, false, false, 0);

    HBox_AutoLogin_Apply = new Gtk.HBox(false, 0);
    VBoxMain_Autologin.pack_end(HBox_AutoLogin_Apply, false, false, 0);

    var BTN_AutoLogin_Apply = new Gtk.Button.with_label(_("Apply"));
    BTN_AutoLogin_Apply.clicked.connect(AutoLogin_Apply_clicked);
    HBox_AutoLogin_Apply.pack_start(BTN_AutoLogin_Apply, true, false, 0);

    window.show_all ();

    load_gtk3_list();
    load_shell_list();
    load_icon_list();

    gdm3setup = Bus.get_proxy_sync (BusType.SYSTEM,"apps.nano77.gdm3setup","/apps/nano77/gdm3setup");

    get_gdm();
    get_autologin();

    ComboBox_gtk.changed.connect(gtk3_theme_changed);
    ComboBox_shell.changed.connect(shell_theme_changed);
    FontButton.font_set.connect(font_set);
    ComboBox_icon.changed.connect(icon_theme_changed);
    ComboBox_cursor.changed.connect(cursor_theme_changed);
    Entry_logo.changed.connect(logo_icon_changed);
    WallpaperChooser.file_changed.connect(wallpaper_filechanged);
    CheckButton_banner.toggled.connect(banner_toggled);
    Entry_banner_text.changed.connect(banner_text_changed);
    CheckButton_user.toggled.connect(user_list_toggled);
    CheckButton_restart.toggled.connect(menu_btn_toggled);


    Gtk.main ();
    return 0;
}


