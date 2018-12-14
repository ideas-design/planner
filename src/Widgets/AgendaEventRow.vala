/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Niels Avonds <niels.avonds@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class AgendaEventRow : Gtk.ListBoxRow {
    public signal void removed (E.CalComponent event);
    public signal void modified (E.CalComponent event);

    public string uid { public get; private set; }
    public string summary { public get; private set; }
    public E.CalComponent calevent { public get; private set; }
    public bool is_allday { public get; private set; default=false; }
    public bool is_multiday { public get; private set; default=false; }
    public Gtk.Revealer revealer { public get; private set; }

    private Gtk.Label event_image;
    private Gtk.Label name_label;
    private Gtk.Label datatime_label;
    private Gtk.Label location_label;

    private bool isUpcoming;

    public AgendaEventRow (E.Source source, E.CalComponent calevent, bool isUpcoming) {
        margin_start = 3;

        this.calevent = calevent;
        this.isUpcoming = isUpcoming;
        unowned iCal.Component ical_event = calevent.get_icalcomponent ();
        uid = ical_event.get_uid ();

        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        //event_image = new Gtk.Image.from_icon_name ("mail-unread-symbolic", Gtk.IconSize.MENU);
        event_image = new Gtk.Label (null);
        event_image.width_request = 3;   
        Maya.Util.style_calendar_color (event_image, cal.dup_color (), true);

        cal.notify["color"].connect (() => {
            Maya.Util.style_calendar_color (event_image, cal.dup_color (), true);
        });

        name_label = new Gtk.Label ("");
        name_label.margin_bottom = 1;
        name_label.hexpand = true;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        datatime_label = new Gtk.Label ("");
        datatime_label.use_markup = true;
        datatime_label.ellipsize = Pango.EllipsizeMode.END;
        datatime_label.xalign = 0;
        datatime_label.valign = Gtk.Align.START;
        datatime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        location_label = new Gtk.Label ("");
        location_label.no_show_all = true;
        location_label.wrap = true;
        location_label.xalign = 0;
        location_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        
        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 6;
        main_grid.margin = 6;
                
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.pack_start (name_label, false, false, 0);  
        box.pack_start (location_label, false, false, 0);        

        main_grid.add (datatime_label);
        main_grid.add (event_image);
        main_grid.add (box);
        /*
        main_grid.attach (event_image, 0, 0, 1, 1);
        main_grid.attach (name_label, 1, 0, 1, 1);
        main_grid.attach (datatime_label, 1, 1, 1, 1);
        main_grid.attach (location_label, 1, 2, 1, 1);
        */

        var event_box = new Gtk.EventBox ();
        event_box.add (main_grid);

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        revealer.add (event_box);
        add (revealer);

        show.connect (() => {
            revealer.set_reveal_child (true);
        });

        hide.connect (() => {
            revealer.set_reveal_child (false);
        });

        // Fill in the information
        update (calevent);
    }
    /**
     * Updates the event to match the given event.
     */
    public void update (E.CalComponent event) {
        unowned iCal.Component ical_event = event.get_icalcomponent ();
        summary = ical_event.get_summary ();
        name_label.set_markup (Markup.escape_text (summary));

        DateTime start_date, end_date;
        Maya.Util.get_local_datetimes_from_icalcomponent (ical_event, out start_date, out end_date);

        is_allday = Maya.Util.is_all_day (start_date, end_date);
        is_multiday = Maya.Util.is_multiday_event (ical_event);

        string start_date_string = start_date.format (Maya.Settings.DateFormat_Complete ());
        string end_date_string = end_date.format (Maya.Settings.DateFormat_Complete ());
        string start_time_string = start_date.format (Maya.Settings.TimeFormat ());
        string end_time_string = end_date.format (Maya.Settings.TimeFormat ());

        datatime_label.show ();
        datatime_label.no_show_all = false;
        if (is_multiday) {
            if (is_allday) {
                datatime_label.label = _(" %s \n %s").printf (start_date_string, end_date_string);
            } else {
                datatime_label.label = _(" %s, %s \n %s, %s").printf (start_date_string, start_time_string, end_date_string, end_time_string);
            }
        } else {
            if (!isUpcoming) {
                if (is_allday) {
                    datatime_label.hide ();
                    datatime_label.no_show_all = true;
                } else {
                    datatime_label.label = _(" %s \n %s ").printf (start_time_string, end_time_string);
                }
            } else {
                if (is_allday) {
                    datatime_label.label = _(" %s").printf (start_date_string);
                } else {
                    datatime_label.label = _(" %s, %s \n %s").printf (start_date_string, start_time_string, end_time_string);
                }
            }
        }

        string location = ical_event.get_location ();
        if (location != null && location != "") {
            location_label.label = location;
            location_label.show ();
        } else {
            location_label.hide ();
            location_label.no_show_all = true;
        }
    }
}
