#!/usr/bin/env python3
"""Make the iPhone shortcut from docs/AIRPLAY.md as a .shortcut file (unsigned).

    python3 scripts/make-airplay-shortcut.py --name "F1 on TV" --app "F1 TV" --bundle com.formula1.ott --do "F1 TV"

iPhones only import signed shortcuts, so sign it on a Mac afterwards:
    shortcuts sign --mode anyone --input "F1 on TV.shortcut" --output "F1 on TV signed.shortcut"
(.github/workflows/shortcut.yml does this on GitHub's Macs.) The bridge's address is not in the file:
the iPhone asks for it once, when the shortcut is added.

What it does: POST {"do": <do>} to <bridge>/api/watch (turns the TV on). On an Apple Watch it then
shows the answer; on the iPhone it sets the playback destination (you pick the TV once) and opens the app.
"""
import argparse
import plistlib
import uuid

OBJ = "￼"  # where a variable sits inside a Shortcuts text


def uid():
    return str(uuid.uuid4()).upper()


def text(s):
    return {"Value": {"string": s}, "WFSerializationType": "WFTextTokenString"}


def text_with(before, out_uuid, out_name, after):
    return {"Value": {"string": before + OBJ + after,
                      "attachmentsByRange": {"{%d, 1}" % len(before):
                                             {"Type": "ActionOutput", "OutputUUID": out_uuid, "OutputName": out_name}}},
            "WFSerializationType": "WFTextTokenString"}


def variable(out_uuid, out_name):
    return {"Value": {"Type": "ActionOutput", "OutputUUID": out_uuid, "OutputName": out_name},
            "WFSerializationType": "WFTextTokenAttachment"}


def action(ident, **params):
    return {"WFWorkflowActionIdentifier": ident, "WFWorkflowActionParameters": params}


def build(name, app, bundle, do, playback_id):
    t_bridge, t_url, t_dev, group = uid(), uid(), uid(), uid()
    actions = [
        # 0: the bridge's address, asked for when the shortcut is added (import question below)
        action("is.workflow.actions.gettext", UUID=t_bridge,
               WFTextActionText=text("http://192.168.1.20:5400")),
        # 1: wake the TV through the bridge
        action("is.workflow.actions.downloadurl", UUID=t_url,
               WFURL=text_with("", t_bridge, "Text", "/api/watch"),
               WFHTTPMethod="POST", WFHTTPBodyType="JSON", ShowHeaders=True,
               WFJSONValues={"Value": {"WFDictionaryFieldValueItems": [
                   {"WFItemType": 0, "WFKey": text("do"), "WFValue": text(do)}]},
                   "WFSerializationType": "WFDictionaryFieldValue"}),
        # 2: which device is this running on
        action("is.workflow.actions.getdevicedetails", UUID=t_dev, WFDeviceDetail="Device Model"),
        # 3: If it is the watch
        action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=0,
               WFCondition=99, WFConditionalActionString="Watch",
               WFInput={"Type": "Variable", "Variable": variable(t_dev, "Device Model")}),
        # 4: the watch can't open apps on the phone: say the TV is ready
        action("is.workflow.actions.showresult", Text=text_with("", t_url, "Contents of URL", "")),
        # 5: Otherwise (the iPhone)
        action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=1),
        # 6: send this phone's video to the TV (tap it once and pick the TV)
        action(playback_id),
        # 7: open the app
        action("is.workflow.actions.openapp", WFAppIdentifier=bundle,
               WFSelectedApp={"BundleIdentifier": bundle, "Name": app}),
        # 8: End If
        action("is.workflow.actions.conditional", GroupingIdentifier=group, WFControlFlowMode=2),
    ]
    return {
        "WFWorkflowActions": actions,
        "WFWorkflowClientVersion": "2302.0.4",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowIcon": {"WFWorkflowIconStartColor": 4282601983, "WFWorkflowIconGlyphNumber": 59446},
        "WFWorkflowTypes": ["WatchKit"],
        "WFWorkflowInputContentItemClasses": [],
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowHasShortcutInputVariables": False,
        "WFWorkflowImportQuestions": [{
            "ActionIndex": 0, "Category": "Parameter", "ParameterKey": "WFTextActionText",
            "Text": "The address your Couch TV phone remote opens, for example http://192.168.1.20:5400",
            "DefaultValue": "http://",
        }],
        "WFQuickActionSurfaces": [],
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--name", default="F1 on TV")
    p.add_argument("--app", default="F1 TV")
    p.add_argument("--bundle", default="com.formula1.ott")
    p.add_argument("--do", default="F1 TV")
    p.add_argument("--playback-id", default="is.workflow.actions.setplaybackdestination")
    p.add_argument("--out")
    a = p.parse_args()
    out = a.out or f"{a.name}.shortcut"
    with open(out, "wb") as f:
        plistlib.dump(build(a.name, a.app, a.bundle, a.do, a.playback_id), f, fmt=plistlib.FMT_BINARY)
    print(out)


if __name__ == "__main__":
    main()
