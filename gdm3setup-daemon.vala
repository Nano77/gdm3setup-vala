// -*- mode: vala; vala-indent-level: 4; indent-tabs-mode: nil -*-
using GLib;

MainLoop loop;
DBusConnection Connection;

struct Subject {
  public string               subject_kind;
  public HashTable<string,Variant> subject_details;
}


struct AuthorizationResult {
    public bool             is_authorized;
    public bool             is_challenge;
    public HashTable<string,string> details;
}

[DBus (name = "org.freedesktop.DBus")]
interface DBUS : Object {
    public abstract uint32 GetConnectionUnixProcessID (string name) throws IOError;
}

[DBus (name = "org.freedesktop.PolicyKit1.Authority")]
interface PolicyKitAuthority : Object {
    public abstract AuthorizationResult CheckAuthorization (Subject subject,
                                                            string                         action_id,
                                                            HashTable<string, string>             details,
                                                            uint32        flags,
                                                            string                         cancellation_id
                                                            ) throws IOError;
}


[DBus (name = "apps.nano77.gdm3setup")]
public class GDM3SETUP_Daemon : Object {
    string[] Get_Bus() {
        string ps_name="";
        string address="";
        string user_name="";
        string dbus_pid="";
        string dbus_address="";
        string ps;

        var d = Dir.open("/proc");
        while ((ps = d.read_name()) != null) {
            if ( FileUtils.test("/proc/%s/comm".printf(ps),FileTest.EXISTS)) {
                string line;
                IOChannel comm = new IOChannel.file("/proc/%s/comm".printf(ps),"r");
                comm.read_line(out ps_name,null,null);
                ps_name = ps_name.replace("\n","");
                if (ps_name=="dbus-daemon") {
                    string[] environdata={};
                    string ev = "";
                    IOChannel environ = new IOChannel.file("/proc/%s/environ".printf(ps),"r");
                    environ.read_line(out ev,null,null);
                    do {
                        if (ev.length>"DBUS_SESSION_BUS_ADDRESS".length) {
                            if (ev[0:"DBUS_SESSION_BUS_ADDRESS".length]=="DBUS_SESSION_BUS_ADDRESS")
                                address = ev;
                        }
                        if (ev.length>"USERNAME".length) {
                            if (ev[0:"USERNAME".length]=="USERNAME")
                                user_name = ev;
                        }

                        environ.read_line(out ev,null,null);
                    }
                    while (ev!=null);

                    if ((user_name=="USERNAME=gdm") & (address!="")) {
                        dbus_address = address["DBUS_SESSION_BUS_ADDRESS".length+1:address.length];
                        dbus_pid = ps;
                    }
                }
            }
        }
        return {dbus_address,dbus_pid};
    }

    bool str_to_bool(string state) {
        bool b_state;
        if (state.down()=="true" | state=="1")
            b_state = true;
        else
            b_state = false;

        return b_state;
    }

    string GetValue(string target,string default_value) {
        string targetfile = "/etc/gdm/custom.conf";
        string contents;
        string ret_val = default_value;
        int i;
        try {
            FileUtils.get_contents(targetfile,out contents,null);
            string[] lines = contents.split("\n",0);
            for (i=0;i<lines.length;i++) {
                string line = lines[i];
                if (line.length > target.length) {
                    if (line[0:target.length+1]==target+"=") {
                        ret_val = line[target.length+1:line.length];
                        break;
                    }
                    else
                        ret_val = default_value;
                }
            }
        }
        catch (FileError e) {
            stderr.printf("File '%s' not found !\n",targetfile);
            ret_val = default_value;
        }
    return ret_val;
    }

void HackShellTheme(bool b) {
    if (b) {
        FileUtils.rename("/usr/share/gnome-shell/theme","/usr/share/gnome-shell/theme.original");
        FileUtils.symlink("/usr/share/gnome-shell/theme.original","/usr/share/gnome-shell/theme");
        FileUtils.symlink("/usr/share/gnome-shell/theme.original","/usr/share/themes/Adwaita/gnome-shell");
        }
    else {
        FileUtils.remove("/usr/share/themes/Adwaita/gnome-shell");
        FileUtils.remove("/usr/share/gnome-shell/theme");
        FileUtils.rename("/usr/share/gnome-shell/theme.original","/usr/share/gnome-shell/theme");
    }
}

string Get_Shell_theme() {
    string shell_theme="Adwaita";
    if (FileUtils.test("/usr/share/gnome-shell/theme",FileTest.IS_SYMLINK)) {
        string theme_path = FileUtils.read_link("/usr/share/gnome-shell/theme");
        if (theme_path == "/usr/share/gnome-shell/theme.original")
            shell_theme="Adwaita";
        else {
            string[] tb_path = theme_path.split("/");
            shell_theme = tb_path[tb_path.length-2];
        }
    }
    else
        shell_theme="Adwaita";

    return shell_theme;
}


void Set_Shell_theme(string val) {
    if (val=="Adwaita")
        HackShellTheme(false);
    else {
        if (! FileUtils.test("/usr/share/gnome-shell/theme",FileTest.IS_SYMLINK)) {
            HackShellTheme(true);
            FileUtils.remove("/usr/share/gnome-shell/theme");
            FileUtils.symlink("/usr/share/themes/%s/gnome-shell".printf(val),"/usr/share/gnome-shell/theme");
        }
    }
}

    bool PolicyKit_Test(GLib.BusName sender,string Action) {
        DBUS dbus_proxy = Bus.get_proxy_sync (BusType.SYSTEM,"org.freedesktop.DBus","/org/freedesktop/DBus/Bus");
        uint32 pid = dbus_proxy.GetConnectionUnixProcessID(sender);
        PolicyKitAuthority proxy_policykit_Authority = Bus.get_proxy_sync(BusType.SYSTEM,"org.freedesktop.PolicyKit1","/org/freedesktop/PolicyKit1/Authority");
        HashTable<string,Variant> subject_details = new HashTable<string,Variant>(str_hash,str_equal);
        subject_details.insert("pid",pid);
        subject_details.insert("start-time",(uint64)0);
        HashTable<string,string> details = new GLib.HashTable<string,string>(str_hash,str_equal);
        details.insert("","");
        AuthorizationResult auth_result = proxy_policykit_Authority.CheckAuthorization({"unix-process",subject_details},Action,details,1,"");
        return auth_result.is_authorized;
    }

    public string SetUI(string name,string val, GLib.BusName sender) {
        if (PolicyKit_Test(sender,"apps.nano77.gdm3setup.set")) {
            if (name!="SHELL_THEME") {
                string[] bus_data = Get_Bus();
                string bus_adrress = bus_data[0];
                string bus_pid = bus_data[1];
                Process.spawn_command_line_sync("su - gdm -s /bin/bash -c \"LANG='%s' DBUS_SESSION_BUS_ADDRESS='%s' DBUS_SESSION_BUS_PID='%s' set_gdm.sh -n '%s' -v '%s' \" ".printf("en_US.utf8",bus_adrress,bus_pid,name,val),null,null,null);
            }
            else
                Set_Shell_theme(val);
            return "OK";
        }
        else {
            return "ERROR : YOU ARE NOT ALLOWED !";
        }
    }

    public string[] GetUI() {
        Process.spawn_command_line_sync("su - gdm -s /bin/sh -c 'LANG=%s get_gdm.sh'".printf("en_US.utf8"));
        string contents;
        FileUtils.get_contents("/tmp/GET_GDM",out contents,null);
        string[] settings = contents.split("\n",0);
        FileUtils.remove("/tmp/GET_GDM");
        settings += "SHELL='%s'".printf(Get_Shell_theme());
        return settings;
    }

    public string SetAutoLogin(bool AUTOLOGIN, string USERNAME,bool TIMED, int TIMED_TIME, GLib.BusName sender) {
        if (PolicyKit_Test(sender,"apps.nano77.gdm3setup.set")) {
            if (AUTOLOGIN) {
                if (TIMED)
                    Process.spawn_command_line_sync("gdmlogin.py -a -u %s -d %i".printf(USERNAME,TIMED_TIME));
                else
                    Process.spawn_command_line_sync("gdmlogin.py -a -u %s".printf(USERNAME));
                }
            else
                Process.spawn_command_line_sync("gdmlogin.py -m");
            return "OK";
        }
        else {
            return "ERROR : YOU ARE NOT ALLOWED !";
        }
    }

    public string[] GetAutoLogin() {
        bool AutomaticLoginEnable = str_to_bool(GetValue("AutomaticLoginEnable","False"));
        string AutomaticLogin = GetValue("AutomaticLogin","");
        bool TimedLoginEnable = str_to_bool(GetValue("TimedLoginEnable","False"));
        string TimedLogin = GetValue("TimedLogin","");
        string TimedLoginDelay = GetValue("TimedLoginDelay","30");

        string AUTOLOGIN = (AutomaticLoginEnable | TimedLoginEnable).to_string();
        string TIMED = TimedLoginEnable.to_string();
        string TIMED_TIME = TimedLoginDelay;
        string USERNAME;

        if (AutomaticLoginEnable)
            USERNAME = AutomaticLogin;

        if (TimedLoginEnable)
            USERNAME = TimedLogin;

        if (!(AutomaticLoginEnable | TimedLoginEnable ))
            USERNAME = "";

    return {AUTOLOGIN,USERNAME,TIMED,TIMED_TIME};
    }

    public void StopDaemon() {
        loop.quit();
    }

}

void on_bus_aquired (DBusConnection conn) {
    conn.register_object ("/apps/nano77/gdm3setup",new GDM3SETUP_Daemon ());
    Connection = conn;
}

int main (string[] args) {

    Bus.own_name (BusType.SYSTEM, "apps.nano77.gdm3setup", BusNameOwnerFlags.NONE,on_bus_aquired,null,null);

    loop = new MainLoop (null,false);
    loop.run();

    return 0;
}


