// -*- mode: vala; vala-indent-level: 4; indent-tabs-mode: nil -*-
using Gtk;
using Gdk;
using GLib;
using Gnome;

const string GDM_BIN_PATH="/usr/sbin/gdm";

[DBus (name = "apps.nano77.gdm3setup")]
interface GDM3SETUP : Object {
    public abstract string SetUI (string name,string value) throws IOError;
    public abstract string[] GetUI () throws IOError;
    public abstract string SetAutoLogin (bool autologin, string username, bool timed, int timed_time) throws IOError;
    public abstract string[] GetAutoLogin () throws IOError; 
    public abstract void StopDaemon () throws IOError;
}

class ImageChooserButton : Gtk.Button {
    private new Label label;
    private new Image image;
    private Separator separator;
    private Box box;
    private string Filename;
    private FileChooserDialog fileChooserDialog;
    private FileFilter filter;
    private Image PreviewImage;
    private Box PreviewBox;
    private Label Label_Size;

    public signal void file_changed ();

    construct {
        this.label = new Label(_("(None)"));
        this.image = new Gtk.Image();
        this.image.set_from_icon_name("fileopen",Gtk.IconSize.SMALL_TOOLBAR);
        this.separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        this.add(this.box);
        this.box.pack_start(this.label,false,false,2);
        this.box.pack_end(this.image,false,false,2);
        this.box.pack_end(this.separator,false,false,2);
        this.box.show_all();
        this.filter = new Gtk.FileFilter();
        this.filter.add_pixbuf_formats();
        this.filter.set_filter_name("Image");
        this.PreviewImage = new Gtk.Image();
        this.PreviewBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
        this.Label_Size = new Gtk.Label("0 x 0");
        this.PreviewBox.set_size_request(200,-1);
        this.PreviewBox.pack_start(this.PreviewImage, false, false, 0);
        this.PreviewImage.show();
        this.PreviewBox.pack_start(this.Label_Size, false, false, 0);
        this.Label_Size.show();
        this.Filename = "";
        this.clicked.connect(this._Clicked);
        this.fileChooserDialog = null;

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

    private void _UpdatePreview() {
        string PreviewURI = this.fileChooserDialog.get_preview_uri();
        File PreviewFile = this.fileChooserDialog.get_preview_file();
        FileInfo PreviewFileInfo;
        long mtime;
        string ThumbnailPath;
        Pixbuf pixbuf;
        string PreviewWidth,PreviewHeight;
        string mimetype;

        if (PreviewURI!=null && PreviewFile !=null) {
            if (! FileUtils.test(PreviewFile.get_path(),FileTest.IS_DIR)) {

                PreviewFileInfo = PreviewFile.query_info("*",FileQueryInfoFlags.NONE,null);
                mtime = PreviewFileInfo.get_modification_time().tv_sec;
                mimetype = PreviewFileInfo.get_content_type();
                DesktopThumbnailFactory ThumbnailFactory = new DesktopThumbnailFactory(DesktopThumbnailSize.NORMAL);
                ThumbnailPath = ThumbnailFactory.lookup(PreviewURI,mtime);
                if (ThumbnailPath != null) {
                    pixbuf = new Pixbuf.from_file(ThumbnailPath);
                    this.PreviewImage.set_from_pixbuf(pixbuf);
                    this.fileChooserDialog.set_preview_widget_active(true);
                }
                else {
                    pixbuf = ThumbnailFactory.generate_thumbnail(PreviewURI,mimetype);
                    ThumbnailFactory.save_thumbnail(pixbuf,PreviewURI,mtime);
                    this.PreviewImage.set_from_pixbuf(pixbuf);
                    this.fileChooserDialog.set_preview_widget_active(true);
                }

                PreviewWidth = pixbuf.get_option("tEXt::Thumb::Image::Width");
                PreviewHeight = pixbuf.get_option("tEXt::Thumb::Image::Height");
                this.Label_Size.set_label( PreviewWidth + " x " + PreviewHeight);
            }
            else 
                this.fileChooserDialog.set_preview_widget_active(false);
        }
        else 
            this.fileChooserDialog.set_preview_widget_active(false);
    }

    void _Clicked() {
        if (this.fileChooserDialog == null) {
            this.fileChooserDialog = new Gtk.FileChooserDialog(_("Select a File"),null,
                                          FileChooserAction.OPEN,
                                          Stock.CANCEL, ResponseType.CANCEL,
                                          Stock.CLEAR, ResponseType.NONE,
                                          Stock.OPEN, ResponseType.ACCEPT);
            this.fileChooserDialog.add_filter(filter);
            this.fileChooserDialog.set_filename(this.Filename);
            this.fileChooserDialog.add_shortcut_folder("/usr/share/backgrounds");
            this.fileChooserDialog.set_preview_widget(this.PreviewBox);
            this.fileChooserDialog.set_preview_widget_active(false);
            this.fileChooserDialog.update_preview.connect(this._UpdatePreview);
            this.fileChooserDialog.response.connect(this.response_cb);
            this.fileChooserDialog.destroy.connect(this.dialog_destroy);
            this.fileChooserDialog.set_transient_for((Gtk.Window)this.get_toplevel());
        }
        this.fileChooserDialog.present();
    }

    void response_cb(int response_id) {
        this.fileChooserDialog.hide();
        if (response_id == Gtk.ResponseType.ACCEPT) {
            this.Filename = this.fileChooserDialog.get_filename();
            this.label.set_label(GLib.Path.get_basename(this.Filename));
            this.file_changed();
        }
        else {
            if (response_id == Gtk.ResponseType.NONE) {
                this.Filename = "";
                this.label.set_label(_("(None)"));
                this.file_changed();
            }
        }
    }

    void dialog_destroy() {
        this.fileChooserDialog = null;
    }
}


class AutoLoginDialog : Gtk.Dialog {
    private Gtk.Box content_area;
    private Gtk.Box Box;
    public Gtk.CheckButton CheckButton_AutoLogin;
    private Gtk.Box Box_username;
    private Gtk.Label Label_username;
    public Gtk.Entry Entry_username;
    private Gtk.Box Box_Delay ;
    public Gtk.CheckButton CheckButton_Delay;
    public Gtk.SpinButton SpinButton_Delay;

    construct {
        this.set_resizable(false);
        this.title = _("GDM AutoLogin Setup");
        this.add_button(Gtk.Stock.CANCEL,Gtk.ResponseType.CANCEL);
        this.add_button(Gtk.Stock.OK,Gtk.ResponseType.OK);
        this.content_area = (Gtk.Box)this.get_content_area();
        this.Box = new Gtk.Box(Gtk.Orientation.VERTICAL,8);
        this.Box.set_border_width(8);
        this.content_area.add(this.Box);

        this.CheckButton_AutoLogin = new Gtk.CheckButton.with_label(_("Enable Automatic Login"));
        this.CheckButton_AutoLogin.toggled.connect(this.AutoLogin_toggled);
        this.Box.pack_start(this.CheckButton_AutoLogin, false, false, 0);
        this.Box_username = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        this.Box_username.set_sensitive(false);
        this.Box.pack_start(this.Box_username, false, false, 0);
        this.Label_username = new Gtk.Label(_("User Name"));
        this.Label_username.set_alignment(0,0.5f);
        this.Box_username.pack_start(this.Label_username, false, false, 0);
        this.Entry_username = new Gtk.Entry();
        this.Box_username.pack_end(this.Entry_username, false, false, 0);
        this.Box_Delay = new Gtk.Box(Gtk.Orientation.HORIZONTAL,8);
        this.Box_Delay.set_sensitive(false);
        this.Box.pack_start(this.Box_Delay, false, false, 0);
        this.CheckButton_Delay = new Gtk.CheckButton.with_label(_("Enable Delay before autologin"));
        this.CheckButton_Delay.toggled.connect(this.Delay_toggled);
        this.Box_Delay.pack_start(CheckButton_Delay, false, false, 0);
        this.SpinButton_Delay = new Gtk.SpinButton.with_range(1,60,1);
        this.SpinButton_Delay.set_value(10);
        this.SpinButton_Delay.set_sensitive(false);
        this.Box_Delay.pack_end(SpinButton_Delay, false, false, 0);
        this.show_all();
    }

    void AutoLogin_toggled() {
        if (this.CheckButton_AutoLogin.get_active()) {
            this.Box_username.set_sensitive(true);
            this.Box_Delay.set_sensitive(true);
        }
        else {
            this.Box_username.set_sensitive(false);
            this.Box_Delay.set_sensitive(false);
        }
    }

    void Delay_toggled() {
        if (CheckButton_Delay.get_active())
            SpinButton_Delay.set_sensitive(true);
        else
            SpinButton_Delay.set_sensitive(false);
    }
}


class AutologinButton : Gtk.Button {
    private bool autologin;
    private string username;
    private bool timed;
    private int time;
    private Gtk.Box box;
    private Gtk.Label label_state;
    private Gtk.Label label_user;
    private Gtk.Separator separator;
    private Gtk.Label label_time;
    private AutoLoginDialog Dialog;

    public signal void changed ();

    construct {
        this.autologin=false;
        this.username="";
        this.timed=false;
        this.time=30;
        this.box= new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
        this.add(this.box);
        this.box.show();
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
        this.Dialog = null;
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
        if (this.Dialog == null) {
            this.Dialog = new AutoLoginDialog();
            this.Dialog.response.connect(this.response_cb);
            this.Dialog.destroy.connect(this.dialog_destroy);
            this.Dialog.set_transient_for((Gtk.Window)this.get_toplevel());
        }
        this.Dialog.CheckButton_AutoLogin.set_active(this.get_autologin());
        this.Dialog.Entry_username.set_text(this.get_username());
        this.Dialog.CheckButton_Delay.set_active(this.get_timed());
        this.Dialog.SpinButton_Delay.set_value(this.get_time());
        this.Dialog.present();
    }

    private void response_cb(int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            if (this.Dialog.CheckButton_AutoLogin.get_active() && this.Dialog.Entry_username.get_text()=="") {
                Gtk.MessageDialog Message = new Gtk.MessageDialog((Gtk.Window)this.get_toplevel(),Gtk.DialogFlags.DESTROY_WITH_PARENT, 
                                        Gtk.MessageType.ERROR,
                                        Gtk.ButtonsType.CLOSE,
                                        _("User Name can't be empty !"));
                Message.run();
                Message.destroy();
            }
            else {
                this.set_autologin(this.Dialog.CheckButton_AutoLogin.get_active());
                this.set_username(this.Dialog.Entry_username.get_text());
                this.set_timed(this.Dialog.CheckButton_Delay.get_active());
                this.set_time(this.Dialog.SpinButton_Delay.get_value_as_int());
                this.Dialog.hide();
                this.changed();
            }
        }
        else
            this.Dialog.hide();
    }

    private void dialog_destroy() {
        this.Dialog = null;
    }

}


class EditButton : Gtk.HBox {
    private Gtk.Button Button;
    private Gtk.Entry Entry;
    public signal void changed();

    construct {
        this.Button = new Gtk.Button.with_label("text");
        this.Button.clicked.connect(this.set_state_active);
        this.add(this.Button);
        this.Button.show();
        this.Entry = new Gtk.Entry();
        this.Entry.key_press_event.connect(this.key_press);
        this.Entry.button_press_event.connect(this.button_press);
        this.Entry.focus_in_event.connect(this.focus_in);
        this.update_size();
    }

    private void update_size() {
        int entry_minimum_width;
        int entry_natural_width;
        int entry_minimum_height;
        int entry_natural_height;
        int button_minimum_width;
        int button_natural_width;
        int preferred_width;

        this.Entry.get_preferred_width(out entry_minimum_width,out entry_natural_width);
        this.Entry.get_preferred_height(out entry_minimum_height,out entry_natural_height);
        this.Button.get_preferred_width(out button_minimum_width,out button_natural_width);

        if ( entry_minimum_width >= button_minimum_width )
            preferred_width = entry_minimum_width;
        else
            preferred_width = button_minimum_width;
        this.set_size_request(preferred_width,entry_minimum_height);
    }

    private void set_state_active(Gtk.Button button) {
        this.Entry.set_text(this.Button.get_label());
        this.remove(this.Button);
        this.add(this.Entry);
        this.Entry.show();
        this.Entry.grab_focus();
    }

    private void set_state_inactive() {
        this.Entry.focus_out_event.disconnect(this.focus_out);
        this.remove(this.Entry);
        this.add(this.Button);
    }

    private bool key_press(Gdk.EventKey event) {
        string k = Gdk.keyval_name(event.keyval);
        if (k == "Return" || k == "KP_Enter" ) {
            this.Button.set_label(this.Entry.get_text());
            this.set_state_inactive();
            this.Button.grab_focus();
            this.update_size();
            this.changed();
        }
        if (k == "Escape") {
            this.set_state_inactive();
            this.Button.grab_focus();
        }
        return false;
    }

    private bool button_press(Gdk.EventButton event) {
        uint b = event.button;
        if (b == 3)
            this.Entry.focus_out_event.disconnect(this.focus_out);
        return false;
    }

    private bool focus_out(Gtk.Widget w,Gdk.EventFocus e) {
        this.set_state_inactive();
        return false;
    }

    private bool focus_in(Gtk.Widget w,Gdk.EventFocus e) {
        this.Entry.focus_out_event.connect(this.focus_out);
        return false;
    }

    public string get_text() {
        return this.Button.get_label();
    }

    public void set_text(string text) {
        this.Button.set_label(text);
        this.update_size();
    }
}

class MainWindow : Gtk.Window {
    private Gtk.Builder Builder;
    private Gtk.Box Box_Main;

    private ImageChooserButton Button_wallpaper;
    private Gtk.ComboBoxText ComboBox_icon;
    private Gtk.ComboBoxText ComboBox_cursor;
    private AutologinButton Button_autologin;
    private Gtk.ComboBoxText ComboBox_shell;
    private ImageChooserButton Button_fallback_logo;
    private ImageChooserButton Button_shell_logo;
    private Gtk.Switch Switch_clock_date;
    private Gtk.Switch Switch_clock_seconds;
    private Gtk.ComboBoxText ComboBox_gtk;
    private Gtk.FontButton Button_font;
    private EditButton Entry_logo_icon;
    private Gtk.CheckButton CheckButton_banner;
    private EditButton Entry_banner_text;
    private Gtk.CheckButton CheckButton_user;
    private Gtk.CheckButton CheckButton_restart;

    private GDM3SETUP proxy;

    private string GTK3_THEME = "";
    private string ICON_THEME = "";
    private string CURSOR_THEME ="";
    private string WALLPAPER = "";
    private string SHELL_THEME = "";
    private string LOGO_ICON = "";
    private string FALLBACK_LOGO = "";
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

    construct {

        //register ImageChooserButton
        stdout.printf("%s\n", typeof (ImageChooserButton) .name ());
        //register AutologinButton
        stdout.printf("%s\n",typeof (AutologinButton) .name ());
        //register EditButton
        stdout.printf("%s\n",typeof (EditButton) .name ());

        this.title = _("GDM3 Setup");
        this.border_width = 10;
        this.window_position = WindowPosition.CENTER;
        this.set_default_size (400, 300);
        this.set_resizable(false);
        this.set_icon_name("preferences-desktop-theme");
        this.destroy.connect(this._close);

        this.Builder = new Gtk.Builder();
        this.Builder.set_translation_domain("gdm3setup");
        this.Builder.add_from_file("/usr/share/gdm3setup/ui/gdm3setup.ui");
        this.Box_Main = (Gtk.Box) this.Builder.get_object("box_main");
        this.add(this.Box_Main);

        this.Button_font = (Gtk.FontButton) this.Builder.get_object("Button_font");
        this.Button_wallpaper = (ImageChooserButton) this.Builder.get_object("Button_wallpaper");
        this.ComboBox_shell = (Gtk.ComboBoxText) this.Builder.get_object("ComboBox_shell");
        this.ComboBox_icon = (Gtk.ComboBoxText) this.Builder.get_object("ComboBox_icon");
        this.ComboBox_cursor = (Gtk.ComboBoxText) this.Builder.get_object("ComboBox_cursor");
        this.Entry_logo_icon = (EditButton) this.Builder.get_object("Entry_logo_icon");
        this.Button_fallback_logo = (ImageChooserButton) this.Builder.get_object("Button_fallback_logo");
        this.Button_shell_logo = (ImageChooserButton) this.Builder.get_object("Button_shell_logo");
        this.ComboBox_gtk = (Gtk.ComboBoxText) this.Builder.get_object("ComboBox_gtk");
        this.CheckButton_banner = (Gtk.CheckButton) this.Builder.get_object("CheckButton_banner");
        this.Entry_banner_text = (EditButton) this.Builder.get_object("Entry_banner_text");
        this.CheckButton_user = (Gtk.CheckButton) this.Builder.get_object("CheckButton_user");
        this.CheckButton_restart = (Gtk.CheckButton) this.Builder.get_object("CheckButton_restart");
        this.Button_autologin = (AutologinButton) this.Builder.get_object("Button_autologin");
        this.Switch_clock_date = (Gtk.Switch) this.Builder.get_object("Switch_clock_date");
        this.Switch_clock_seconds = (Gtk.Switch) this.Builder.get_object("Switch_clock_seconds");

        this.proxy = Bus.get_proxy_sync (BusType.SYSTEM,"apps.nano77.gdm3setup","/apps/nano77/gdm3setup");

        this.load_gtk3_list();
        this.load_shell_list();
        this.load_icon_list();
        this.get_gdm();
        this.get_autologin();

        this.ComboBox_gtk.changed.connect(this.gtk3_theme_changed);
        this.ComboBox_shell.changed.connect(this.shell_theme_changed);
        this.Button_font.font_set.connect(this.font_set);
        this.ComboBox_icon.changed.connect(this.icon_theme_changed);
        this.ComboBox_cursor.changed.connect(this.cursor_theme_changed);
        this.Entry_logo_icon.changed.connect(this.logo_icon_changed);
        this.Button_fallback_logo.file_changed.connect(this.fallback_logo_filechanged);
        this.Button_shell_logo.file_changed.connect(this.shell_logo_changed);
        this.Button_wallpaper.file_changed.connect(this.wallpaper_filechanged);
        this.CheckButton_banner.toggled.connect(this.banner_toggled);
        this.Entry_banner_text.changed.connect(this.banner_text_changed);
        this.CheckButton_user.toggled.connect(this.user_list_toggled);
        this.CheckButton_restart.toggled.connect(this.menu_btn_toggled);
        this.Button_autologin.changed.connect(this.autologin_changed);
        this.Switch_clock_date.notify["active"].connect(this.clock_date_toggled);
        this.Switch_clock_seconds.notify["active"].connect(this.clock_seconds_toggled);
        this.AdaptVersion();

        //https://bugzilla.gnome.org/show_bug.cgi?id=653579
        this.ComboBox_icon.set_entry_text_column(0);
        this.ComboBox_icon.set_id_column(1);
        this.ComboBox_cursor.set_entry_text_column(0);
        this.ComboBox_cursor.set_id_column(1);
        this.ComboBox_shell.set_entry_text_column(0);
        this.ComboBox_shell.set_id_column(1);
        this.ComboBox_gtk.set_entry_text_column(0);
        this.ComboBox_gtk.set_id_column(1);

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
        this.FALLBACK_LOGO = unquote(get_setting("FALLBACK_LOGO",settings));
        this.SHELL_LOGO = unquote(get_setting("SHELL_LOGO",settings));
        this.USER_LIST = bool.parse(get_setting("USER_LIST",settings));
        this.MENU_BTN = bool.parse( get_setting("BTN" ,settings));
        this.BANNER = bool.parse(get_setting("BANNER",settings));
        this.BANNER_TEXT = unquote(get_setting("BANNER_TEXT",settings));
        this.CLOCK_DATE = str_to_bool(get_setting("CLOCK_DATE",settings));
        this.CLOCK_SECONDS = str_to_bool(get_setting("CLOCK_SECONDS",settings));
        this.ComboBox_gtk.set_active_iter(get_iter(this.ComboBox_gtk.get_model(),this.GTK3_THEME));
        this.ComboBox_shell.set_active_iter(get_iter(this.ComboBox_shell.get_model(),this.SHELL_THEME));
        this.Button_font.set_font_name(this.FONT_NAME);
        this.Button_wallpaper.set_filename(this.WALLPAPER);
        this.ComboBox_icon.set_active_iter(get_iter(this.ComboBox_icon.get_model(),this.ICON_THEME));
        this.ComboBox_cursor.set_active_iter(get_iter(this.ComboBox_cursor.get_model(),this.CURSOR_THEME));
        this.Entry_logo_icon.set_text(this.LOGO_ICON);
        this.Button_fallback_logo.set_filename(this.FALLBACK_LOGO);
        this.Button_shell_logo.set_filename(this.SHELL_LOGO);
        this.CheckButton_banner.set_active(this.BANNER);
        this.Entry_banner_text.set_text(this.BANNER_TEXT);
        this.CheckButton_user.set_active(this.USER_LIST);
        this.CheckButton_restart.set_active(this.MENU_BTN);
        this.Entry_banner_text.set_sensitive(this.BANNER);
        this.Switch_clock_date.set_active(this.CLOCK_DATE);
        this.Switch_clock_seconds.set_active(this.CLOCK_SECONDS);
    }

    private void  AdaptVersion() { 
        string output;
        bool GSexists;
        int GdmSubVersion;

        Process.spawn_command_line_sync(GDM_BIN_PATH+" --version",out output,null,null);
        GdmSubVersion = int.parse(output.split(" ",0)[1].split(".",0)[1]);
        GSexists = FileUtils.test("/usr/bin/gnome-shell",FileTest.EXISTS);

        if ( GdmSubVersion >= 3 ) {
            this.Entry_logo_icon.hide();
            ((Gtk.Label)this.Builder.get_object("Label_logo_icon")).hide();
            this.Button_fallback_logo.show();
            ((Gtk.Label)this.Builder.get_object("Label_fallback_logo")).show();
        }
        else {
            this.Entry_logo_icon.show();
            ((Gtk.Label)this.Builder.get_object("Label_logo_icon")).show();
            this.Button_fallback_logo.hide();
            ((Gtk.Label)this.Builder.get_object("Label_fallback_logo")).hide();
        }
        if ( ! GSexists || GdmSubVersion == 0 )
            ((Gtk.Notebook)this.Builder.get_object("notebook1")).remove_page(1);
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
        this.Button_autologin.set_autologin(this.AUTOLOGIN_ENABLED);
        this.Button_autologin.set_username(this.AUTOLOGIN_USERNAME);
        this.Button_autologin.set_timed(this.AUTOLOGIN_TIMED);
        this.Button_autologin.set_time(this.AUTOLOGIN_TIME);
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
        string font_name = this.Button_font.get_font_name();
        if (this.FONT_NAME != font_name) { 
            if (this.set_gdm("FONT",font_name)) {
                this.FONT_NAME = font_name;
                stdout.printf("Font Changed : %s\n",this.FONT_NAME);
            }
            else
                this.Button_font.set_font_name(this.FONT_NAME);
        }
    }

    private void wallpaper_filechanged() {
        string wallpaper = this.Button_wallpaper.get_filename();
        if (this.WALLPAPER != wallpaper) {
            if (this.set_gdm("WALLPAPER",wallpaper)) {
                this.WALLPAPER = wallpaper;
                stdout.printf("Wallpaper Changed : %s\n", this.WALLPAPER);
            }
            else
                this.Button_wallpaper.set_filename(this.WALLPAPER);
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

    private void  fallback_logo_filechanged() {
        string fallback_logo = this.Button_fallback_logo.get_filename();
        if (this.FALLBACK_LOGO != fallback_logo) {
            if (this.set_gdm("FALLBACK_LOGO",fallback_logo)) {
                this.FALLBACK_LOGO = fallback_logo;
                stdout.printf ("Fallback Logo Changed : %s\n",this.SHELL_LOGO);
            }
            else {
                this.Button_fallback_logo.set_filename(this.FALLBACK_LOGO);
            }
        }
    }

    private void shell_logo_changed() {
        string shell_logo = this.Button_shell_logo.get_filename();
        if (this.SHELL_LOGO != shell_logo) {
            if (this.set_gdm("SHELL_LOGO",shell_logo)) {
                this.SHELL_LOGO = shell_logo;
                stdout.printf ("Shell Logo Changed : %s\n",this.SHELL_LOGO);
            }
            else
                this.Button_shell_logo.set_filename(this.SHELL_LOGO);
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
        bool autologin_enabled = this.Button_autologin.get_autologin();
        string autologin_username = this.Button_autologin.get_username();
        bool autologin_timed = this.Button_autologin.get_timed();
        int autologin_time = this.Button_autologin.get_time();
        if (this.set_autologin(autologin_enabled,autologin_username,autologin_timed,autologin_time)) {
            this.AUTOLOGIN_ENABLED = autologin_enabled;
            this.AUTOLOGIN_USERNAME = autologin_username;
            this.AUTOLOGIN_TIMED = autologin_timed;
            this.AUTOLOGIN_TIME = autologin_time;
        }
        else {
            this.Button_autologin.set_autologin(this.AUTOLOGIN_ENABLED);
            this.Button_autologin.set_username(this.AUTOLOGIN_USERNAME);
            this.Button_autologin.set_timed(this.AUTOLOGIN_TIMED);
            this.Button_autologin.set_time(this.AUTOLOGIN_TIME);
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
    window.show ();

    Gtk.main ();
    return 0;
}


