# 0.31.0 draft — exact approved artwork pending

Implemented: all-grade reserve and field withdrawal; preserved cooldown/hidden-charge state; reserve + field recipe planning and atomic consumption; all crafted results appear on the field; reserve-only crafting requires an empty cell and fails without consuming ingredients when the field is full; seven ordered catalog/reserve grades; small and hidden cards; removed automatic round selector rewards while retaining paid-draw 100-pull pity.

Existing round gold and boss gold are unchanged. Existing saved selector tickets remain usable; no more round selector tickets are granted.

The user explicitly requires the exact supplied three-screen composite, not regenerated artwork. UI atlas expects `game/assets/screens/approved-layout.png`. The attachment's original bytes are not currently available to the editing tools. Regenerated images are not included. The build gate prevents exporting an APK without this original image. Functional tests may run with a plain fallback; that is not a release design.

Pending: attach approved original PNG, verify atlas crop coordinates and touch targets against that file, inspect actual rendered screens, complete Android installation and interaction checks, then publish v0.31.0.

## Functional verification

Latest functional commit: `a8cee19ad1bf353dc34c44916cdeafb40f41eb3d`.
[GitHub Actions verification](https://github.com/jck35511/drd/actions/runs/41580139082): all 44 regression scripts passed, including all 52 unit kinds moving field/reserve, all 39 recipes from reserve with immediate field placement, mixed ingredients, repeated clicks, missing duplicate materials, full-field behavior and save restoration. Field ingredients are consumed first so their cell can hold the result on a full board. Android export remains gated on the original approved composite image. These checks do not establish pixel matching or Android behavior of the pending image.
