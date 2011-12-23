// -*- mode: vala; vala-indent-level: 4; indent-tabs-mode: nil -*-
using Gtk;
using GLib;

[DBus (name = "apps.nano77.gdm3setup")]
interface GDM3SETUP : Object {
    public abstract string SetUI (string name,string value) throws IOError;
    public abstract string[] GetUI () throws IOError;
    public abstract string SetAutoLogin (bool autologin, string username, bool timed, int timed_time) throws IOError;
    public abstract string[] GetAutoLogin () throws IOError; 
    public abstract void StopDaemon () throws IOError;
}

class WallpaperChooserButton : Gtk.Button {
    private Label label;
    private Image image;
    private Separator separator;
    private HBox box;
    private string Filename;
    private FileChooserDialog fileChooserDialog;
    private FileFilter filter;

    public signal void file_changed ();

    public WallpaperChooserButton() {
        this.box = new Gtk.HBox(false,0);
        this.add(this.box);
        this.label = new Label(_("(None)"));
        this.image = new Gtk.Image();
        this.image.set_from_icon_name("fileopen",Gtk.IconSize.SMALL_TOOLBAR);
        this.separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        this.box.pack_start(this.label,false,false,2);
        this.box.pack_end(this.image,false,false,2);
        this.box.pack_end(this.separator,false,false,2);
        this.filter = new Gtk.FileFilter();
        this.filter.add_pixbuf_formats();
        this.filter.set_filter_name("Image");

        this.Filename = "";
        this.clicked.connect(this._Clicked);
    }

    public string get_filename() {
        return this.Filename;
    }

    public void set_filename(string filename) {
        this.Filename = filename;
        if (filename != "") 
            this.label.set_label( GLib.Path.get_basename(filename));
        else
            this.label.set_label(_("(None)"));
        this.file_changed();
    }

    void _Clicked() {
        this.fileChooserDialog = new FileChooserDialog(_("Select a File"),null,
                                      FileChooserAction.OPEN,
                                      Stock.CANCEL, ResponseType.CANCEL,
                                      Stock.CLEAR, ResponseType.NONE,
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
            if (result==ResponseType.NONE) {
                this.Filename = "";
                this.label.set_label(_("(None)"));
                fileChooserDialog.destroy();
                this.file_changed();
            }
            else 
                fileChooserDialog.destroy();
    }
}


class AutoLoginWindow : Gtk.Window {
    private Gtk.VBox VBoxMain;
    public Gtk.CheckButton CheckButton_AutoLogin;
    private Gtk.HBox HBox_username;
    private Gtk.Label Label_username;
    public Gtk.Entry Entry_username;
    private Gtk.HBox HBox_Delay ;
    public Gtk.CheckButton CheckButton_Delay;
    public Gtk.SpinButton SpinButton_Delay;
    private Gtk.HBox HBox_Apply;
    private Gtk.Button BTN_Apply;

    public signal void changed ();
    
    public AutoLoginWindow(Gtk.Window parent_window) {
        this.title = _("GDM AutoLogin Setup");
        this.border_width = 10;
        this.window_position = WindowPosition.CENTER_ON_PARENT;
        this.set_modal(true);
        this.set_transient_for(parent_window);
        this.set_default_size (400, 300);
        this.set_resizable(false);
        this.set_icon_name("preferences-desktop-theme");
        this.delete_event.connect(this._Close);
        this.VBoxMain = new Gtk.VBox (false, 8);
        this.add(this.VBoxMain);
        this.CheckButton_AutoLogin = new Gtk.CheckButton.with_label(_("Enable Automatic Login"));
        this.CheckButton_AutoLogin.toggled.connect(this.AutoLogin_toggled);
        this.VBoxMain.pack_start(this.CheckButton_AutoLogin, false, false, 0);
        this.HBox_username = new Gtk.HBox(false, 0);
        this.HBox_username.set_sensitive(false);
        this.VBoxMain.pack_start(this.HBox_username, false, false, 0);
        this.Label_username = new Gtk.Label(_("User Name"));
        this.Label_username.set_alignment(0,0.5f);
        this.HBox_username.pack_start(this.Label_username, false, false, 0);
        this.Entry_username = new Gtk.Entry();
        this.Entry_username.changed.connect(this.username_changed);
        this.HBox_username.pack_end(this.Entry_username, false, false, 0);
        this.HBox_Delay = new Gtk.HBox(false, 8);
        this.HBox_Delay.set_sensitive(false);
        this.VBoxMain.pack_start(this.HBox_Delay, false, false, 0);
        this.CheckButton_Delay = new Gtk.CheckButton.with_label(_("Enable Delay before autologin"));
        this.CheckButton_Delay.toggled.connect(this.Delay_toggled);
        this.HBox_Delay.pack_start(CheckButton_Delay, false, false, 0);
        this.SpinButton_Delay = new Gtk.SpinButton.with_range(1,60,1);
        this.SpinButton_Delay.set_value(10);
        this.SpinButton_Delay.set_sensitive(false);
        this.HBox_Delay.pack_end(SpinButton_Delay, false, false, 0);
        this.HBox_Apply = new Gtk.HBox(false, 0);
        this.VBoxMain.pack_end(HBox_Apply, false, false, 0);
        this.BTN_Apply = new Gtk.Button.with_label(_("Apply"));
        this.BTN_Apply.clicked.connect(this.Apply_clicked);
        this.HBox_Apply.pack_start(BTN_Apply, true, false, 0);
    }

    bool _Close(Gdk.EventAny event) {
        this.hide();
        return true;
    }

    void AutoLogin_toggled() {
        if (this.CheckButton_AutoLogin.get_active()) {
            this.HBox_username.set_sensitive(true);
            this.HBox_Delay.set_sensitive(true);
        }
        else {
            this.HBox_username.set_sensitive(false);
            this.HBox_Delay.set_sensitive(false);
        }

        if (this.Entry_username.get_text()!="" || this.CheckButton_AutoLogin.get_active()==false )
            this.HBox_Apply.set_sensitive(true);
        else
            this.HBox_Apply.set_sensitive(false);
    }

    void username_changed() {
        if (Entry_username.get_text()!="")
            HBox_Apply.set_sensitive(true);
        else
            HBox_Apply.set_sensitive(false);
    }

    void Delay_toggled() {
        if (CheckButton_Delay.get_active())
            SpinButton_Delay.set_sensitive(true);
        else
            SpinButton_Delay.set_sensitive(false);
    }

    void Apply_clicked() {
        this.changed();
        this.hide();
    }


}


class AutologinButton : Gtk.Button {
    private bool autologin;
    private string username;
    private bool timed;
    private int time;
    private Gtk.HBox box;
    private Gtk.Label label_state;
    private Gtk.Label label_user;
    private Gtk.Separator separator;
    private Gtk.Label label_time;
    private AutoLoginWindow window;

    public signal void changed ();

    public AutologinButton(Gtk.Window parent_window) {
        this.autologin=false;
        this.username="";
        this.timed=false;
        this.time=30;
        this.box= new Gtk.HBox(false,0);
        this.add(this.box);
        this.label_state = new Gtk.Label(_("Disabled"));
        this.label_state.set_no_show_all(true);
        this.label_state.show();
        this.box.pack_start(this.label_state,true,true,2);
        this.label_user = new Gtk.Label("USER");
        this.label_user.set_no_show_all(true);
        this.box.pack_start(this.label_user,false,false,2);
        this.label_time = new Gtk.Label("TIME");
        this.label_time.set_no_show_all(true);
        this.box.pack_end(this.label_time,false,false,2);
        this.separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        this.separator.set_no_show_all(true);
        this.box.pack_end(this.separator,false,false,2);
        this.clicked.connect(this._clicked);
        this.window = new AutoLoginWindow(parent_window);
        this.window.changed.connect(this._changed);
    }

    public void  update() {
        if (this.autologin) {
            this.label_state.hide();
            this.label_user.show();
            if (this.timed) {
                this.separator.show();
                this.label_time.show();
            }
            else {
                this.separator.hide();
                this.label_time.hide();
            }
        }
        else {
            this.label_state.show();
            this.label_user.hide();
            this.separator.hide();
            this.label_time.hide();
        }
        this.label_user.set_text(this.username);
        this.label_time.set_text("%i s".printf(this.time));
    }

    public void set_autologin(bool b) {
        this.autologin = b;
        this.update();
    }

    public bool get_autologin() {
        return this.autologin;
    }

    public void set_timed(bool timed) {
        this.timed=timed;
        this.update();
    }

    public bool get_timed() {
        return this.timed;
    }

    public void set_time(int time) {
        this.time=time;
        this.update();
    }

    public int get_time() {
        return this.time;
    }

    public void set_username(string username) {
        this.username=username;
        this.update();
    }

    public string get_username() {
        return this.username;
    }

    private void _clicked() {
        this.window.CheckButton_AutoLogin.set_active(this.get_autologin());
        this.window.Entry_username.set_text(this.get_username());
        this.window.CheckButton_Delay.set_active(this.get_timed());
        this.window.SpinButton_Delay.set_value(this.get_time());
        this.window.show_all();
    }

    private void _changed() {
        this.set_autologin(this.window.CheckButton_AutoLogin.get_active());
        this.set_username(this.window.Entry_username.get_text());
        this.set_timed(this.window.CheckButton_Delay.get_active());
        this.set_time(this.window.SpinButton_Delay.get_value_as_int());
        this.changed();
    }
}

class MainWindow : Gtk.Window {
    private Gtk.VBox VBox_Main;
    private Gtk.Notebook notebook;
    private Gtk.VBox Box_common;
    private Gtk.HBox Box_common_main;
    private Gtk.VBox Box_common_Left;
    private Gtk.VBox Box_common_Right;
    private Gtk.VBox Box_shell;
    private Gtk.HBox Box_shell_main;
    private Gtk.VBox Box_shell_Left;
    private Gtk.VBox Box_shell_Right;
    private Gtk.HBox Box_shell_date;
    private Gtk.HBox Box_shell_seconds;
    private Gtk.VBox Box_gtk;
    private Gtk.HBox Box_gtk_main;
    private Gtk.VBox Box_gtk_Left;
    private Gtk.VBox Box_gtk_Right;
    private Gtk.HBox HBox_restart;
    private Gtk.HBox HBox_user;
    private Gtk.Label common_label;
    private Gtk.Label shell_label;
    private Gtk.Label gtk_label;

    private Gtk.Label Label_wallpaper;
    private WallpaperChooserButton WallpaperChooser;
    private Gtk.Label Label_icon;
    private Gtk.ComboBoxText ComboBox_icon;
    private Gtk.Label Label_cursor;
    private Gtk.ComboBoxText ComboBox_cursor;
    private Gtk.Label Label_autologin;
    private AutologinButton BTN_autologin;

    private Gtk.Label Label_shell;
    private Gtk.ComboBoxText ComboBox_shell;
    private Gtk.Label Label_shell_logo;
    private WallpaperChooserButton BTN_shell_logo;
    private Gtk.Label Label_clock_date;
    private Gtk.Switch Switch_clock_date;
    private Gtk.Label Label_clock_seconds;
    private Gtk.Switch Switch_clock_seconds;

    private Gtk.Label Label_gtk;
    private Gtk.ComboBoxText ComboBox_gtk;
    private Gtk.Label Label_font;
    private Gtk.FontButton FontButton;
    private Gtk.Label Label_logo_icon;
    private Gtk.Entry Entry_logo_icon;
    private Gtk.CheckButton CheckButton_banner;
    private Gtk.Entry Entry_banner_text;
    private Gtk.CheckButton CheckButton_user;
    private Gtk.CheckButton CheckButton_restart;

    private GDM3SETUP proxy;

    private string GTK3_THEME = "";
    private string ICON_THEME = "";
    private string CURSOR_THEME ="";
    private string WALLPAPER = "";
    private string SHELL_THEME = "";
    private string LOGO_ICON = "";
    private string SHELL_LOGO = "";
    private bool USER_LIST = false;
    private bool MENU_BTN = false;
    private bool BANNER = true;
    private string BANNER_TEXT = "";
    private string FONT_NAME = "";
    private bool CLOCK_DATE=false;
    private bool CLOCK_SECONDS=false;
    private bool AUTOLOGIN_ENABLED=false;
    private string AUTOLOGIN_USERNAME="";
    private bool AUTOLOGIN_TIMED=false;
    private int AUTOLOGIN_TIME=30;

    public MainWindow() {
        this.title = _("GDM3 Setup");
        this.border_width = 10;
        this.window_position = WindowPosition.CENTER;
        this.set_default_size (400, 300);
        this.set_resizable(false);
        this.set_icon_name("preferences-desktop-theme");
        this.destroy.connect(this._close);

        this.VBox_Main = new Gtk.VBox (false, 0);
        this.add(this.VBox_Main);
        this.notebook = new Gtk.Notebook();
        this.VBox_Main.pack_start(this.notebook, false, false, 0);

        this.Box_common = new Gtk.VBox (false, 0);
        this.Box_common.set_border_width(10);
        this.common_label = new Gtk.Label(_("General"));
        this.notebook.append_page(this.Box_common,this.common_label);
        this.Box_common_main = new Gtk.HBox (false, 10);
        this.Box_common.pack_start(this.Box_common_main, false, false, 0);
        this.Box_common_Left = new Gtk.VBox (true, 0);
        this.Box_common_main.pack_start(this.Box_common_Left, false, false, 0);
        this.Box_common_Right = new Gtk.VBox (true, 0);
        this.Box_common_main.pack_end(this.Box_common_Right, false, false, 0);

        this.Box_shell = new Gtk.VBox (false, 0);
        this.Box_shell.set_border_width(10);
        this.shell_label = new Gtk.Label("GnomeShell");
        this.notebook.append_page(this.Box_shell,this.shell_label);
        this.Box_shell_main = new Gtk.HBox (false, 0);
        this.Box_shell.pack_start(this.Box_shell_main, false, false, 0);
        this.Box_shell_Left = new Gtk.VBox (true, 0);
        this.Box_shell_main.pack_start(this.Box_shell_Left, false, false, 0);
        this.Box_shell_Right = new Gtk.VBox (true, 0);
        this.Box_shell_main.pack_end(this.Box_shell_Right, false, false, 0);
        this.Box_shell_date = new Gtk.HBox (false, 0);
        this.Box_shell.pack_start(this.Box_shell_date, false, false, 5);
        this.Box_shell_seconds = new Gtk.HBox (false, 0);
        this.Box_shell.pack_start(this.Box_shell_seconds, false, false, 5);

        this.Box_gtk = new Gtk.VBox(false, 0);
        this.Box_gtk.set_border_width(10);
        this.gtk_label = new Gtk.Label("GTK");
        this.notebook.append_page(this.Box_gtk,this.gtk_label);
        this.Box_gtk_main = new Gtk.HBox(false, 0);
        this.Box_gtk.pack_start(this.Box_gtk_main, false, false, 0);
        this.Box_gtk_Left = new Gtk.VBox(true, 0);
        this.Box_gtk_main.pack_start(this.Box_gtk_Left, false, false, 0);
        this.Box_gtk_Right = new Gtk.VBox(true, 0);
        this.Box_gtk_main.pack_end(this.Box_gtk_Right, false, false, 0);

        this.Label_wallpaper = new Gtk.Label(_("Wallpaper"));
        this.Label_wallpaper.set_alignment(0,0.5f);
        this.Box_common_Left.pack_start(this.Label_wallpaper, false, false, 0);
        this.WallpaperChooser = new WallpaperChooserButton();
        this.Box_common_Right.pack_start(this.WallpaperChooser, false, false, 0);
        this.Label_icon = new Gtk.Label(_("Icon theme"));
        this.Label_icon.set_alignment(0,0.5f);
        this.Box_common_Left.pack_start(this.Label_icon, false, false, 0);
        this.ComboBox_icon = new Gtk.ComboBoxText();
        this.Box_common_Right.pack_start(this.ComboBox_icon, false, false, 0);
        this.Label_cursor = new Gtk.Label(_("Cursor theme"));
        this.Label_cursor.set_alignment(0,0.5f);
        this.Box_common_Left.pack_start(this.Label_cursor, false, false, 0);
        this.ComboBox_cursor = new Gtk.ComboBoxText();
        this.Box_common_Right.pack_start(this.ComboBox_cursor, false, false, 0);
        this.Label_autologin = new Gtk.Label(_("AutoLogin"));
        this.Label_autologin.set_alignment(0,0.5f);
        this.Box_common_Left.pack_start(this.Label_autologin, false, false, 0);
        this.BTN_autologin = new AutologinButton(this);
        this.Box_common_Right.pack_start(this.BTN_autologin, false, false, 0);

        this.Label_shell = new Gtk.Label(_("Shell theme"));
        this.Label_shell.set_alignment(0,0.5f);
        this.Box_shell_Left.pack_start(this.Label_shell, false, false, 0);
        this.ComboBox_shell = new Gtk.ComboBoxText();
        this.Box_shell_Right.pack_start(this.ComboBox_shell, false, false, 0);
        this.Label_shell_logo = new Gtk.Label(_("Shell Logo"));
        this.Label_shell_logo.set_alignment(0,0.5f);
        this.Box_shell_Left.pack_start(this.Label_shell_logo, false, false, 0);
        this.BTN_shell_logo = new WallpaperChooserButton();
        this.Box_shell_Right.pack_start(this.BTN_shell_logo, false, false, 0);
        this.Label_clock_date = new Gtk.Label(_("Show Date in Clock"));
        this.Label_clock_date.set_alignment(0,0.5f);
        this.Box_shell_date.pack_start(this.Label_clock_date, false, false, 0);
        this.Switch_clock_date = new Gtk.Switch();
        this.Box_shell_date.pack_end(this.Switch_clock_date, false, false, 0);
        this.Label_clock_seconds = new Gtk.Label(_("Show Seconds in Clock"));
        this.Label_clock_seconds.set_alignment(0,0.5f);
        this.Box_shell_seconds.pack_start(this.Label_clock_seconds, false, false, 0);
        this.Switch_clock_seconds = new Gtk.Switch();
        this.Box_shell_seconds.pack_end(this.Switch_clock_seconds, false, false, 0);

        this.Label_gtk = new Gtk.Label(_("GTK3 theme"));
        this.Label_gtk.set_alignment(0,0.5f);
        this.Box_gtk_Left.pack_start(this.Label_gtk, false, false, 0);
        this.ComboBox_gtk = new Gtk.ComboBoxText();
        this.Box_gtk_Right.pack_start(this.ComboBox_gtk, false, false, 0);
        this.Label_font = new Gtk.Label(_("Font"));
        this.Label_font.set_alignment(0,0.5f);
        this.Box_gtk_Left.pack_start(this.Label_font, false, false, 0);
        this.FontButton = new Gtk.FontButton();
        this.Box_gtk_Right.pack_start(this.FontButton, false, false, 0);
        this.Label_logo_icon = new Gtk.Label(_("Logo Icon"));
        this.Label_logo_icon.set_alignment(0,0.5f);
        this.Box_gtk_Left.pack_start(this.Label_logo_icon, false, false, 0);
        this.Entry_logo_icon = new Gtk.Entry();
        this.Box_gtk_Right.pack_start(this.Entry_logo_icon, false, false, 0);
        this.CheckButton_banner = new Gtk.CheckButton.with_label (_("Enable Banner"));
        this.Box_gtk_Left.pack_start(this.CheckButton_banner, false, false, 0);
        this.Entry_banner_text = new Gtk.Entry();
        this.Entry_banner_text.set_sensitive(false);
        this.Box_gtk_Right.pack_start(this.Entry_banner_text, false, false, 0);
        this.HBox_user = new Gtk.HBox (false, 0);
        this.Box_gtk.pack_start(this.HBox_user, false, false, 5);
        this.CheckButton_user = new Gtk.CheckButton.with_label (_("Disable User List"));
        this.HBox_user.pack_start(this.CheckButton_user, false, false, 0);
        this.HBox_restart = new Gtk.HBox (false, 0);
        this.Box_gtk.pack_start(this.HBox_restart, false, false, 5);
        this.CheckButton_restart = new Gtk.CheckButton.with_label(_("Disable Restart Buttons"));
        this.HBox_restart.pack_start(this.CheckButton_restart, false, false, 0);


        this.proxy = Bus.get_proxy_sync (BusType.SYSTEM,"apps.nano77.gdm3setup","/apps/nano77/gdm3setup");

        this.load_gtk3_list();
        this.load_shell_list();
        this.load_icon_list();
        this.get_gdm();
        this.get_autologin();

        this.ComboBox_gtk.changed.connect(this.gtk3_theme_changed);
        this.ComboBox_shell.changed.connect(this.shell_theme_changed);
        this.FontButton.font_set.connect(this.font_set);
        this.ComboBox_icon.changed.connect(this.icon_theme_changed);
        this.ComboBox_cursor.changed.connect(this.cursor_theme_changed);
        this.Entry_logo_icon.changed.connect(this.logo_icon_changed);
        this.BTN_shell_logo.file_changed.connect(this.shell_logo_changed);
        this.WallpaperChooser.file_changed.connect(this.wallpaper_filechanged);
        this.CheckButton_banner.toggled.connect(this.banner_toggled);
        this.Entry_banner_text.changed.connect(this.banner_text_changed);
        this.CheckButton_user.toggled.connect(this.user_list_toggled);
        this.CheckButton_restart.toggled.connect(this.menu_btn_toggled);
        this.BTN_autologin.changed.connect(this.autologin_changed);
        this.Switch_clock_date.notify["active"].connect(this.clock_date_toggled);
        this.Switch_clock_seconds.notify["active"].connect(this.clock_seconds_toggled);

    }

    private void load_gtk3_list() {
        string name,file;
        var d = Dir.open("/usr/share/themes/");
        while ((name = d.read_name()) != null) {
            file = "/usr/share/themes/%s/gtk-3.0/".printf(name);
            if (FileUtils.test (file,FileTest.IS_DIR)) {
                this.ComboBox_gtk.append_text(name);
            }
        }
    }

    private void load_shell_list() {
        string name,file,file2;
        var d = Dir.open("/usr/share/themes/");
        ComboBox_shell.append_text("Adwaita");
        while ((name = d.read_name()) != null) {
            file = "/usr/share/themes/%s/gnome-shell/".printf(name);
            if (FileUtils.test (file,FileTest.IS_DIR)) {
                file2 = "/usr/share/themes/%s/gnome-shell/gdm.css".printf(name);
                if (FileUtils.test (file2,FileTest.EXISTS)) {
                    this.ComboBox_shell.append_text(name);
                }
            }
        }
    }

    private void load_icon_list() {
        string name,file;
        var d = Dir.open("/usr/share/icons/");
        while ((name = d.read_name()) != null) {
            file = "/usr/share/icons/%s/".printf(name);
            if (FileUtils.test (file,FileTest.IS_DIR)) {
                file = "/usr/share/icons/%s/cursors/".printf(name);
                if (FileUtils.test (file,FileTest.IS_DIR))
                    this.ComboBox_cursor.append_text(name);
                else 
                    this.ComboBox_icon.append_text(name);
            }
        }
    }

    private void _close() {
        try {
            this.proxy.StopDaemon();
        }
        catch {
            stderr.printf("");
        }
        Gtk.main_quit();
    }

    private bool set_gdm(string name,string value) {
        if (this.proxy.SetUI(name,value)=="OK" )
            return true;
        else
            return false;
    }

    private void get_gdm() {
        string[] settings = this.proxy.GetUI();
        this.GTK3_THEME = get_setting("GTK",settings);
        this.SHELL_THEME = get_setting("SHELL",settings);
        this.FONT_NAME = unquote(get_setting("FONT",settings));
        this.ICON_THEME = get_setting("ICON",settings);
        this.CURSOR_THEME = get_setting("CURSOR",settings);
        string BKG = get_setting("WALLPAPER",settings);
        if (BKG.length>9)
            this.WALLPAPER = BKG[8:BKG.length-1];
        else
            this.WALLPAPER = "";
        this.LOGO_ICON = get_setting("LOGO_ICON",settings);
        this.SHELL_LOGO = unquote(get_setting("SHELL_LOGO",settings));
        this.USER_LIST = bool.parse(get_setting("USER_LIST",settings));
        this.MENU_BTN = bool.parse( get_setting("BTN" ,settings));
        this.BANNER = bool.parse(get_setting("BANNER",settings));
        this.BANNER_TEXT = get_setting("BANNER_TEXT",settings);
        this.CLOCK_DATE = str_to_bool(get_setting("CLOCK_DATE",settings));
        this.CLOCK_SECONDS = str_to_bool(get_setting("CLOCK_SECONDS",settings));
        this.ComboBox_gtk.set_active_iter(get_iter(this.ComboBox_gtk.get_model(),this.GTK3_THEME));
        this.ComboBox_shell.set_active_iter(get_iter(this.ComboBox_shell.get_model(),this.SHELL_THEME));
        this.FontButton.set_font_name(this.FONT_NAME);
        this.WallpaperChooser.set_filename(this.WALLPAPER);
        this.ComboBox_icon.set_active_iter(get_iter(this.ComboBox_icon.get_model(),this.ICON_THEME));
        this.ComboBox_cursor.set_active_iter(get_iter(this.ComboBox_cursor.get_model(),this.CURSOR_THEME));
        this.Entry_logo_icon.set_text(this.LOGO_ICON);
        this.BTN_shell_logo.set_filename(this.SHELL_LOGO);
        this.CheckButton_banner.set_active(this.BANNER);
        this.Entry_banner_text.set_text(this.BANNER_TEXT);
        this.CheckButton_user.set_active(this.USER_LIST);
        this.CheckButton_restart.set_active(this.MENU_BTN);
        this.Entry_banner_text.set_sensitive(this.BANNER);
        this.Switch_clock_date.set_active(this.CLOCK_DATE);
        this.Switch_clock_seconds.set_active(this.CLOCK_SECONDS);
    }

    private bool set_autologin(bool autologin,string username,bool timed,int time) {
        if (this.proxy.SetAutoLogin(autologin,username,timed,time)=="OK")
            return true;
        else
            return false;
    }

    private void get_autologin() {
        string[] Data = this.proxy.GetAutoLogin();
        this.AUTOLOGIN_ENABLED = str_to_bool(Data[0]);
        this.AUTOLOGIN_USERNAME = Data[1];
        this.AUTOLOGIN_TIMED = str_to_bool(Data[2]);
        this.AUTOLOGIN_TIME = int.parse(Data[3]);
        this.BTN_autologin.set_autologin(this.AUTOLOGIN_ENABLED);
        this.BTN_autologin.set_username(this.AUTOLOGIN_USERNAME);
        this.BTN_autologin.set_timed(this.AUTOLOGIN_TIMED);
        this.BTN_autologin.set_time(this.AUTOLOGIN_TIME);
    }

    private void gtk3_theme_changed() {
        string gtk_theme = this.ComboBox_gtk.get_active_text();
        if (gtk_theme!=unquote(this.GTK3_THEME)) {
            if (this.set_gdm("GTK_THEME",gtk_theme)) {
                this.GTK3_THEME = gtk_theme;
                stdout.printf("GTK3 Theme Changed : %s\n",this.GTK3_THEME);
            }
            else
                this.ComboBox_gtk.set_active_iter(get_iter(this.ComboBox_gtk.get_model(),this.GTK3_THEME));
        }
    }

    private void shell_theme_changed() {
        string shell_theme = ComboBox_shell.get_active_text();
        if (shell_theme!=unquote(this.SHELL_THEME)) {
            if (this.set_gdm("SHELL_THEME",shell_theme)) {
                this.SHELL_THEME = shell_theme;
                stdout.printf("SHELL Theme Changed : %s\n",this.SHELL_THEME);
            }
            else
                this.ComboBox_shell.set_active_iter(get_iter(this.ComboBox_shell.get_model(),this.SHELL_THEME));
        }
    }

    private void font_set() {
        string font_name = this.FontButton.get_font_name();
        if (this.FONT_NAME != font_name) { 
            if (this.set_gdm("FONT",font_name)) {
                this.FONT_NAME = font_name;
                stdout.printf("Font Changed : %s\n",this.FONT_NAME);
            }
            else
                this.FontButton.set_font_name(this.FONT_NAME);
        }
    }

    private void wallpaper_filechanged() {
        string wallpaper = this.WallpaperChooser.get_filename();
        if (this.WALLPAPER != wallpaper) {
            if (this.set_gdm("WALLPAPER",wallpaper)) {
                this.WALLPAPER = wallpaper;
                stdout.printf("Wallpaper Changed : %s\n", this.WALLPAPER);
            }
            else
                this.WallpaperChooser.set_filename(this.WALLPAPER);
        }
    }

    private void icon_theme_changed() {
        string icon_theme = this.ComboBox_icon.get_active_text();
        if (unquote(this.ICON_THEME) != icon_theme) {
            if (this.set_gdm("ICON_THEME",icon_theme)) {
                this.ICON_THEME = icon_theme;
                stdout.printf ("Icon Theme Changed : %s\n", this.ICON_THEME);
            }
            else
                this.ComboBox_icon.set_active_iter(get_iter(this.ComboBox_icon.get_model(),this.ICON_THEME));
        }
    }

    private  void cursor_theme_changed() {
        string cursor_theme = this.ComboBox_cursor.get_active_text();
        if (unquote(this.CURSOR_THEME) != cursor_theme) {
            if (this.set_gdm("CURSOR_THEME",cursor_theme)) {
                this.CURSOR_THEME = cursor_theme;
                stdout.printf ("Cursor Theme Changed : %s\n" , this.CURSOR_THEME);
            }
            else
                this.ComboBox_cursor.set_active_iter(get_iter(this.ComboBox_cursor.get_model(),this.CURSOR_THEME));
        }
    }

    private void logo_icon_changed() {
        string logo_icon = this.Entry_logo_icon.get_text();
        if (this.LOGO_ICON != logo_icon) {
            if (this.set_gdm("LOGO_ICON",logo_icon)) {
                this.LOGO_ICON = logo_icon;
                stdout.printf ("Logo Icon Changed : %s\n" , this.LOGO_ICON);
            }
            else
                this.Entry_logo_icon.set_text(this.LOGO_ICON);
        }
    }

    private void shell_logo_changed() {
        string shell_logo = this.BTN_shell_logo.get_filename();
        if (this.SHELL_LOGO != shell_logo) {
            if (this.set_gdm("SHELL_LOGO",shell_logo)) {
                this.SHELL_LOGO = shell_logo;
                stdout.printf ("Shell Logo Changed : %s\n",this.SHELL_LOGO);
            }
            else
                this.BTN_shell_logo.set_filename(this.SHELL_LOGO);
        }
    }

    private void banner_toggled() {
        bool banner = this.CheckButton_banner.get_active();
        if (banner!=this.BANNER) {
            if (this.set_gdm("BANNER",banner.to_string())) {
                this.BANNER = banner;
                stdout.printf ("Banner Changed : %s\n",this.BANNER.to_string());
                if (this.BANNER)
                    this.Entry_banner_text.set_sensitive(true);
                else
                    this.Entry_banner_text.set_sensitive(false);
            }
            else
                this.CheckButton_banner.set_active(this.BANNER);
        }
    }

    private void banner_text_changed() {
        string banner_text = this.Entry_banner_text.get_text();
        if (this.BANNER_TEXT!=banner_text) {
            if (this.set_gdm("BANNER_TEXT",banner_text)) {
                this.BANNER_TEXT = banner_text;
                stdout.printf ("Banner Text Changed : %s\n", this.BANNER_TEXT);
            }
            else
                this.Entry_banner_text.set_text(this.BANNER_TEXT);
        }
    }

    private void user_list_toggled() {
        bool user_list = this.CheckButton_user.get_active();
        if (this.USER_LIST != user_list) {
            if (this.set_gdm("USER_LIST",user_list.to_string())) {
                this.USER_LIST = user_list;
                stdout.printf ("User List Changed : %s\n" ,this.USER_LIST.to_string());
             }
            else
                this.CheckButton_user.set_active(this.USER_LIST);
        }
    }

    private void menu_btn_toggled() {
        bool menu_btn = this.CheckButton_restart.get_active();
        if (this.MENU_BTN != menu_btn) {
            if (this.set_gdm("MENU_BTN",menu_btn.to_string())) {
                this.MENU_BTN = menu_btn;
                stdout.printf ("Menu Btn Changed : %s\n",this.MENU_BTN.to_string());
            }
            else
                this.CheckButton_restart.set_active(this.MENU_BTN);
        }
    }

    private void autologin_changed() {
        bool autologin_enabled = this.BTN_autologin.get_autologin();
        string autologin_username = this.BTN_autologin.get_username();
        bool autologin_timed = this.BTN_autologin.get_timed();
        int autologin_time = this.BTN_autologin.get_time();
        if (this.set_autologin(autologin_enabled,autologin_username,autologin_timed,autologin_time)) {
            this.AUTOLOGIN_ENABLED = autologin_enabled;
            this.AUTOLOGIN_USERNAME = autologin_username;
            this.AUTOLOGIN_TIMED = autologin_timed;
            this.AUTOLOGIN_TIME = autologin_time;
        }
        else {
            this.BTN_autologin.set_autologin(this.AUTOLOGIN_ENABLED);
            this.BTN_autologin.set_username(this.AUTOLOGIN_USERNAME);
            this.BTN_autologin.set_timed(this.AUTOLOGIN_TIMED);
            this.BTN_autologin.set_time(this.AUTOLOGIN_TIME);
        }
    }

    private void clock_date_toggled() {
        bool clock_date = this.Switch_clock_date.get_active();
        if (this.CLOCK_DATE != clock_date) {
            if (this.set_gdm("CLOCK_DATE",clock_date.to_string())) {
                this.CLOCK_DATE = clock_date;
                stdout.printf ("Clock Date toggled : %s\n",this.CLOCK_DATE.to_string());
            }
            else
                this.Switch_clock_date.set_active(this.CLOCK_DATE);
        }
    }

    private void clock_seconds_toggled() {
        bool clock_seconds = this.Switch_clock_seconds.get_active();
        if (this.CLOCK_SECONDS != clock_seconds) {
            if (this.set_gdm("CLOCK_SECONDS",clock_seconds.to_string())) {
                this.CLOCK_SECONDS = clock_seconds;
                stdout.printf ("Clock Seconds toggled : %s\n", this.CLOCK_SECONDS.to_string());
            }
            else
                this.Switch_clock_seconds.set_active(this.CLOCK_SECONDS);
        }
    }
}


//------------------------------------------------------



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

bool str_to_bool(string state) {
    if (state.down()=="true")
        return true;
    else
        return false;
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




int main (string[] args) {
    Gtk.init (ref args);

    MainWindow window = new MainWindow();
    window.show_all ();

    Gtk.main ();
    return 0;
}


