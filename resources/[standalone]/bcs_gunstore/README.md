# bcs_gunstore

Ownable gun stores for FiveM, fully integrated with **ox_inventory**. Browsing and
buying happens inside the native ox_inventory shop UI — there is **no standalone NUI**.
Stores can be created/edited/deleted in-game by admins, purchased by players, and
managed by their owners (stock, prices, name, blip).

## Features

- 🛒 **Native ox_inventory shop** – players browse stock and buy weapons/ammo in the
  normal inventory shop window, with live stock counts.
- 🏪 **Ownable** – any player can buy an unowned store; admins can also hand ownership
  to a player directly.
- 💸 **Sell back to the system** – owners can sell their store back for a configurable
  percentage of its price (`Config.resellPercent`); it returns to the for-sale pool.
- 🧍 **NPC or point target** – a store's target can be a spawned ped (any
  [ped model](https://docs.fivem.net/docs/game-references/ped-models/)) or a plain
  point. Set/clear the ped per store at any time.
- 🎯 **Raycast placement preview** – placing or moving a store shows a live preview at
  your crosshair: a transparent ghost ped (or a ground marker) you can **rotate**
  (arrow keys / mouse wheel) and confirm with **E**.
- 🛠️ **In-game admin editor (CRUD)** – create stores with the placement tool, edit
  settings/owner/blip/ped, move them, or delete them.
- 🏷️ **Dynamic wholesale stock prices** – when system restocking is on, owners *pay*
  per unit to restock. Admins set a per-item wholesale price (stored in the DB, shared
  by all stores) in `/gunstore`; unset items use `Config.defaultStockPrice`. Stops
  owners restocking for free.
- 💼 **In-game owner manager** – stock up, set per-item prices, restock, rename the
  store (the blip name follows the store name), change the blip color/sprite/scale,
  withdraw earnings, and sell the store back.
- 💰 **Revenue routing** – every sale credits the store's balance, which the owner
  withdraws. Stock is persisted to the database.
- 🔌 **Framework bridge** – works on **Qbox (qbx)**, **QBCore (qb)** and **ESX**
  (auto-detected). Add more frameworks under `bridge/`.

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_target](https://github.com/overextended/ox_target) *(optional — falls back to a
  marker + keypress if not present; toggle with `Config.useTarget`)*

## Installation

1. Drop the `bcs_gunstore` folder into your resources.
2. Import the database schema:
   ```
   mysql -u <user> -p <database> < sql/bcs_gunstore.sql
   ```
   (or import `sql/bcs_gunstore.sql` via HeidiSQL / phpMyAdmin).
3. Add to your `server.cfg` **after** your framework, ox_lib and ox_inventory:
   ```
   ensure bcs_gunstore
   ```
4. (Optional) Review `config/config.lua` — framework is auto-detected, but you can
   force it, change the currency item, blip defaults, starter catalogue, item
   whitelist, etc.

## Usage

### Admins
- Run **`/gunstore`** (command name is configurable) to open the admin menu.
  - **Create a store** – fill in name / price / blip / optional ped model, then place
    it with the raycast preview: aim at the spot, **arrow keys** or **mouse wheel** to
    rotate, **E** to confirm, **Backspace** to cancel.
  - **All gun stores** – pick any store to edit its settings (incl. ped model), manage
    stock, move it (same raycast preview), set/clear the owner, or delete it.
  - **Stock prices** – set the per-item wholesale cost owners pay to restock from the
    system. Saved to the DB and shared by every store; items with no price use
    `Config.defaultStockPrice`. Admins always restock for free.
- Admin status comes from the framework bridge (`isPlayerAdmin`) or the ACE
  permission `bcs_gunstore.admin` (configurable).

### Players
- Approach a store (ox_target or the **[E]** prompt) and choose:
  - **Browse store** – opens the ox_inventory shop to buy.
  - **Buy this store** – appears when the store is unowned and for sale.

### Owners
- Approach your store and choose **Manage store**:
  - **Stock & prices** – **Add item** lets you pick a weapon/ammo from your own
    inventory (no typing item names) and set its price. **Restock** behaviour depends on
    `Config.RestockFromSystem`:
    - `false` – moves the actual items out of your inventory into the store.
    - `true` – pulls stock from the system, charging the admin-set wholesale price per
      unit (paid from `Config.stockAccount`). The restock menu shows the per-unit cost.

    You can also reprice or remove items.
  - **Edit name & blip** – rename the store (blip name updates) and change the blip
    color/sprite/scale.
  - **Earnings** – withdraw the money your store has made.
  - **Sell store to system** – give up ownership for a refund of
    `Config.resellPercent` × the store price (hidden when `Config.allowOwnerSell` is
    off). The store returns to the for-sale pool.

> Store purchases, sell-back refunds and withdrawals use `Config.purchaseAccount` /
> `Config.withdrawAccount` (default **bank**); restock costs use `Config.stockAccount`.
> Item purchases inside the shop use the ox_inventory `Config.currency` item
> (default `money`).

## How the ox_inventory integration works

Each store is registered at runtime as an ox_inventory shop via
`exports.ox_inventory:RegisterShop('bcs_gunstore_<id>', { name, inventory })`, with no
fixed `locations` so this resource controls the blip/interaction itself. Opening uses
`exports.ox_inventory:openInventory('shop', { type = 'bcs_gunstore_<id>' })`.

Revenue and stock are handled with a `buyItem` hook
(`exports.ox_inventory:registerHook('buyItem', ...)`): on each purchase the store
balance is increased, the item stock is decremented, and both are saved to the
database. Re-stocking re-registers the shop so customers see the updated inventory.

## Item names

Items must be valid ox_inventory items. Weapons use the uppercase game name
(`WEAPON_PISTOL`), ammo uses the ox_inventory item name (`ammo-9`, `ammo-rifle`, …).
Use `Config.allowedItems` to restrict what owners may stock.

## Adding another framework

Create `bridge/<name>/client.lua` and `bridge/<name>/server.lua` following the
existing files, implement the same global functions (`getPlayerIdentifier`,
`isPlayerAdmin`, `GetPlayerMoney`, `RemovePlayerMoney`, `AddPlayerMoney`,
`getPlayerName`, …), add them to `fxmanifest.lua`, and add the detection branch in
`init.lua`.
