# Translation Help

This markdown file is to help people make their own translations. It explains what each field in the JSON actually is for.

## How do I get cell and button IDs?

Cell, Category and Subcategory IDs are revealed by enabling debug mode in the game's settings.
The button IDs can be found in the code, and this markdown file will also show them

## Translation variables

In the text, @variablename gets replaced with the variable.

## Fields:

| Field format                   | What it means for the language interpreter                                                                                              | Variables                     |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| cellid.title                   | "The value of this field should be the title of the cell with ID cellid"                                                                |                               |
| cellid.desc                    | "The value of this field should be the description of the cell with ID cellid"                                                          |                               |
| buttonid.title                 | "The value of this field should be the title of the button with ID buttonid"                                                            |                               |
| buttonid.desc                  | "The value of this field should be the description of the button with ID buttonid"                                                      |                               |
| categoryid.title               | "The value of this field should be the title of the category with ID categoryid"                                                        |                               |
| categoryid.desc                | "The value of this field should be the description of the category with ID categoryid"                                                  |                               |
| subcategoryid.title            | "The value of this field should be the title of the subcategory with ID subcategoryid"                                                  |                               |
| subcategoryid.desc             | "The value of this field should be the description of the subcategory with ID subcategoryid"                                            |                               |
| title                          | The title to show in the languages menu                                                                                                 |                               |
| editor                         | The name of the editor screen                                                                                                           |                               |
| puzzles                        | The name of the puzzles screen                                                                                                          |                               |
| worlds                         | The name of the worlds screen                                                                                                           |                               |
| puzzle                         | The name of the puzzle button                                                                                                           |                               |
| delete                         | The name of the delete button                                                                                                           |                               |
| multiplayer                    | The name of the multiplayer screen and Multiplayer settings tab                                                                         |                               |
| settings                       | The name of the settings screen                                                                                                         |                               |
| languages                      | The name of the language screen                                                                                                         |                               |
| credits                        | The name of the credits screen                                                                                                          |                               |
| version                        | The name of the version screen                                                                                                          |                               |
| loadLevel                      | The name of the load level button                                                                                                       |                               |
| saveErrorDesc                  | The description of the Invalid Save error message                                                                                       | error                         |
| yes                            | For every confirmation prompt, this is what would get shown instead of Yes                                                              |                               |
| no                             | For every confirmation prompt, this is what would get shown instead of No                                                               |                               |
| world_del_title                | The title of the world delete confirmation prompt                                                                                       | world                         |
| world_del_content              | The message to show in the confirmation prompt                                                                                          |                               |
| add                            | The name of the add button in some pages                                                                                                |                               |
| create_world                   | The title of the Create a World page                                                                                                    |                               |
| width                          | The name of the width box                                                                                                               |                               |
| height                         | The name of the height box                                                                                                              |                               |
| title_box                      | The name of the title box in worlds or when creating a texture pack                                                                     |                               |
| description                    | The name of the description box in worlds                                                                                               |                               |
| play                           | The name of the play button                                                                                                             |                               |
| connect                        | The name of the connect button in multiplayer                                                                                           |                               |
| remove                         | The name of the delete button in multiplayer and worlds                                                                                 |                               |
| ip_address                     | The name of the IP / Address text box in Multiplayer                                                                                    |                               |
| add_server                     | Title of the Add Server page                                                                                                            |                               |
| multiplayer_servers            | The title of the multiplayer servers that is different than `multiplayer` because it shows as the title of the page but not of the tile |                               |
| update                         | The name of the update checker and of the Update button in the language downloader                                                      |                               |
| versionError                   | The text to show when an error occurs duing update checking                                                                             | error                         |
| version_ok                     | The text to show when the current version IS the most up-to-date                                                                        |                               |
| version_out_of_date            | The text to show when the current version ISN'T the most up-to-date                                                                     |                               |
| shop                           | The title of the in-game skin store                                                                                                     |                               |
| quit                           | The name of the Quit button to close the app                                                                                            |                               |
| update_delay                   | The name of the Update Delay setting                                                                                                    |                               |
| realistic_render               | The name of the Realistic Rendering setting                                                                                             |                               |
| subticking                     | The name of the Subticking setting                                                                                                      |                               |
| titles_description             | The name of the Titles and Description setting                                                                                          |                               |
| ui_scale                       | The name of the UI Scale setting                                                                                                        |                               |
| music_volume                   | The name of the Music Volume setting                                                                                                    |                               |
| debug_mode                     | The name of the Debug Mode setting                                                                                                      |                               |
| interpolation                  | The name of the Interpolation setting                                                                                                   |                               |
| cellbar                        | The name of the Cellbar setting                                                                                                         |                               |
| exit                           | The name of the Exit button in the Editor Menu or title of the exit button                                                              |                               |
| exit_desc                      | The description of the Exit button in puzzle mode                                                                                       |                               |
| clear                          | The name of the Clear button in the Editor Menu                                                                                         |                               |
| wrapModeOn                     | The title to show when Wrap Mode is enabled                                                                                             |                               |
| wrapModeOff                    | The title to show when Wrap Mode is disabled                                                                                            |                               |
| lang_down                      | The title of the language downloader page                                                                                               |                               |
| install                        | For the word Install, commonly in the language downloader                                                                               |                               |
| local_update                   | The text of the dialog telling the user a translation has locally updated                                                               | name                          |
| local_install                  | Like local_update, but it shows it when the users installs it                                                                           | name                          |
| local_update_content           | The content of the dialog for when the user updates a translation locally                                                               |                               |
| local_install_content          | The content of the dialog for when the user installs a translation locally                                                              |
| locally_removed                | The title of the dialog for when the user locally deleted a translation                                                                 | name                          |
| locally_removed_content        | The content of the dialog for when the user locally deleted a translation                                                               |                               |
| fullscreen                     | The name of the Fullscreen Window setting                                                                                               |                               |
| audioDevice                    | The name of the current audio device text                                                                                               |                               |
| sfx_volume                     | The name of the SFX volume setting                                                                                                      |                               |
| lerp_speed                     | The name of the Lerp Speed setting                                                                                                      |                               |
| min_node_size                  | The name of the Minimum Node Size setting                                                                                               |                               |
| middle_move                    | The name of the Middle Click Move setting                                                                                               |                               |
| music_type                     | The name of the Music setting                                                                                                           |                               |
| error                          | The word to replace Error with                                                                                                          |                               |
| load_blueprint_error           | The description of the blueprint load error dialog                                                                                      | error                         |
| download_lang                  | The name of the Download Languages button                                                                                               |                               |
| clear_storage                  | The name of the Clear Storage button                                                                                                    |                               |
| erase                          | The word to use when displaying Erase                                                                                                   |                               |
| cancel                         | The word to use when displaying Cancel                                                                                                  |                               |
| preprocess_packets             | The name of the Preprocess Sent Packets setting                                                                                         |                               |
| resize_and_clear               | The name of the Resize & Clear dialog                                                                                                   |                               |
| select_blueprints              | The name of the Select Blueprints name in the delete blueprints dialog                                                                  |                               |
| blueprint_name_and_description | The name of the dialogs with the title of Blueprint Name & Description                                                                  |                               |
| change_name_and_description    | The name of the Change Name & Description button when saving in editor                                                                  |                               |
| disconnected                   | The name of the Disconnected dialog                                                                                                     |                               |
| disconnected_desc              | The contents of the Disconnected dialog                                                                                                 |                               |
| saved_blueprint                | The name of the Saved Blueprint dialog                                                                                                  |                               |
| saved_blueprint_desc           | The description of the Saved Blueprint dialog                                                                                           |                               |
| add_to_builtin                 | The name of the Add to Built-in button                                                                                                  |                               |
| saved_level                    | The name of the Saved Level dialog                                                                                                      |                               |
| saved_level_desc               | The content of the Saved Level dialog                                                                                                   |                               |
| resize                         | The name of the Resize button and dialog                                                                                                |                               |
| texture_packs                  | The name of the Texture Packs page                                                                                                      |                               |
| enable_all                     | The title of the Enable All button                                                                                                      |                               |
| reload                         | The title of the Reload button                                                                                                          |                               |
| no_texturepacks                | The text to display when there are no installed texture packs                                                                           |                               |
| audio                          | Name of the Audio settings tab                                                                                                          |                               |
| general                        | Name of the General settings tab                                                                                                        |                               |
| graphics                       | The name of the Graphics settings tab                                                                                                   |                               |
| up / left / right / down       | You can probably figure out what words these replace                                                                                    |                               |
| install_from_file              | The name of the Install from File button found in the Texturepacks UI                                                                   |                               |
| performance                    | The name of the Performance tab in Settings                                                                                             |                               |
| benchmark                      | The name of the Benchmark button                                                                                                        |                               |
| background_rect                | The name of the Replace Background Image with Rectangle setting                                                                         |                               |
| benchmark_length               | The name of the Benchmark Length setting                                                                                                |                               |
| chunk_size                     | The name of the Chunk Size setting                                                                                                      |                               |
| translator_mode                | The name of the Translator Mode                                                                                                         |                               |
| property.cellid.propertykey    | The name of the property with the property key "propertykey" from the cell with id "cellid"                                             |                               |
| export                         | The name of the Export button                                                                                                           |                               |
| modify                         | The name of the Modify button                                                                                                           |                               |
| modify_tp                      | The name of the Modify (texture pack name) dialog title                                                                                 | name                          |
| create_tp                      | The name of the Create Texture Pack dialog                                                                                              |                               |
| create                         | The name of the Create buttons                                                                                                          |                               |
| session_history                | The name of the Session History button                                                                                                  |                               |
| grid_history                   | The name of the Grid History button                                                                                                     |                               |
| load                           | The name of the Load button                                                                                                             |                               |
| level_from_history             | The title of a level from Grid or Session History                                                                                       | i - The index (starting at 0) |
| top_left                       | The name of the Top Left corner                                                                                                         |                               |
| top_right                      | The name of the Top Right corner                                                                                                        |                               |
| bottom_right                   | The name of the Bottom Right corner                                                                                                     |                               |
| bottom_left                    | The name of the Bottom Left corner                                                                                                      |                               |
| resize_corner                  | The name of the Resizing Corner                                                                                                         |                               |
| save_on_exit                   | The name of the Save Grid In History Upon Exit setting                                                                                  |                               |
| chat_msg                       | The name of the Send Chat Message dialog                                                                                                |                               |
| send                           | The name of the Send button                                                                                                             |                               |
| msg                            | The name of the Message field                                                                                                           |                               |
| no_msgs                        | The name of the No Messages text                                                                                                        |                               |
| guest                          | The name of the Guest role                                                                                                              |                               |
| member                         | The name of the Member role                                                                                                             |                               |
| admin                          | The name of the Admin role                                                                                                              |                               |
| owner                          | The name of the Owner role                                                                                                              |                               |
| kick                           | The name of the Kick button                                                                                                             |                               |
| cursor_precision               | The name of the Cursor Precision setting                                                                                                |                               |
| packet_queue_limit             | The name of the Packet Queue Limit                                                                                                      |                               |
| achievements                   | The name of the Achievements tab                                                                                                        |                               |
| choose_color                   | The name of the Choose a Color dialog                                                                                                   |                               |
| restore_default                | The name of the Restore to Default button                                                                                               |                               |
| theme                          | The name of the Theme settings tab                                                                                                      |                               |
| grid_opacity                   | The name of Grid Opacity setting                                                                                                        |                               |
| game_bg                        | The name of the Game Background setting                                                                                                 |                               |
| cellbar_background             | The name of the Cell Bar Background setting                                                                                             |                               |
| cellbar_border                 | The name of the Cell Bar Border setting                                                                                                 |                               |
| infobox_background             | The name of the Info Box Background setting                                                                                             |                               |
| infobox_border                 | The name of the Info Box Border setting                                                                                                 |                               |
| ui_button_opacity              | The name of the UI Button Opacity setting                                                                                               |                               |
| cell_button_opacity            | The name of the Cell Button Opacity                                                                                                     |                               |
| info_box_title                 | The name of the Info Box Title setting                                                                                                  |                               |
| info_box_desc                  | The name of the Info Box Description setting                                                                                            |                               |
| editor_menu_bg                 | The name of the Editor Menu Background setting                                                                                          |                               |
| editor_menu_button_opacity     | The name of the Editor Menu Button Opacity setting                                                                                      |                               |
| editor_menu_slider_active      | The name of the Editor Menu Slider Active Color setting                                                                                 |                               |
| editor_menu_slider_inactive    | The name of the Editor Menu Slider Inactive Color setting                                                                               |                               |
| mods                           | The Mods title                                                                                                                          |                               |
| view_cells                     | The name of the View Cells button                                                                                                       |                               |
| view_modules                   | The name of the View Modules dialog                                                                                                     |                               |
| copy_old_instance              | The name of the Copy Old Instance button and dialog                                                                                     |                               |
| transfering_blueprints         | The Transfering Blueprints event (for Copy Old Instance)                                                                                |                               |
| transfering_texture_packs      | The Transfering Texture Packs event (for Copy Old Instance)                                                                             |                               |
| transfering_mods               | The Transfering Game Mods event (for Copy Old Instance)                                                                                 |                               |
| transfering_modules            | The Transfering Modules event (for Copy Old Instance)                                                                                   |                               |
| transfer_success               | The Successfully Transfered Game Data event (for Copy Old Instance)                                                                     |                               |

## Button IDs:

- Back button - `back-btn`
- Load new puzzle - `m-load-btn`
- Save button - `save-btn`
- Load button - `load-btn`
- Wrap button - `wrap-btn`
- Rotate CW - `rot-cw-btn`
- Rotate CCW - `rot-ccw-btn`
- Select button - `select-btn`
- Copy button - `copy-btn`
- Cut button - `cut-btn`
- Delete button (for selections) - `del-btn`
- Paste button - `paste-btn`
- Play / Pause button - `play-btn`
- One Tick button - `onetick-btn`
- Restore button - `restore-btn`
- Set Initial button - `setinitial-btn`
- Save as Blueprint button - `save-blueprint-btn`
- Load as Blueprint button - `load-blueprint-btn`
- Delete Blueprints button - `del-blueprint-btn`
- Property Editor button - `prop-edit-btn`
- Chat Editor button - `chat-btn`

## Example of JSON

Translations use the JSON markup language.
It is a markup language for describing objects with a syntax similar-ish to JavaScript's objects.

Simple example:

```json
{
  "field": "content"
}
```

Those curly brackets (aka `{` and `}`) are only at the start it to mark it as an object.

When typing multiple field-value pairs, add commas inbetween them.
Like so:

```json
{
  "field": "content",
  "other_field": "other content"
}
```

The last field-value pair must not have a , at the end or the parser fails and you get an error.

# This is hard to remember...

"Is there a simpler way of getting all the keys?"
Yes! Translator mode, available since 2.2.0.0! You enable it in your settings, and all newly-rendered text that can be translated will be changed to the translation key, aka, what you gotta put as the field.

It works for everything, even properties!

Hope this helped you!
