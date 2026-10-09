# Keynote script: Supply chain (6 minutes)

Persona: **Paul Zikopoulos**, Supply Chain Operations Manager at **Pacific Crest Distribution**.
The story: overnight, a container gets stuck in port.
By 9 am the AI has found the stock somewhere else, priced the freight, drafted the transfer, told the customers and flagged the supplier who keeps missing deadlines.
Paul makes every decision.

## Before you go on stage

1. Start the database, the API and the web app (see README), then open http://localhost:3000 at 1920x1080.
2. Click an empty area of the page, then press `Shift+I` and `8` to switch to Supply chain.
3. Press `Shift+R` to reset, so all three signals are open and the activity panel only shows seeded history.
4. Check the dot at the far right of the header.
Green means live, gray means offline.
If the Wi-Fi is doubtful, press `Shift+O` now; offline looks identical.
5. Keep the cursor out of text fields whenever you use a shortcut.

## 0:00 to 0:30 · Open on the morning

**On screen:** "Good morning, Paul", "I reviewed 9 shipments overnight" and three signals.

**Say:**
> "This is Paul's morning in supply chain operations.
> Normally the first hour goes on chasing emails, carrier portals and spreadsheets to work out what broke overnight.
> Instead, the assistant has already been through the inbound shipments, the customer orders and the supplier feeds.
> One container is held at the Port of Los Angeles. Three customer orders depend on it. Two suppliers missed their commitments.
> These counts are live queries against the systems, not numbers typed into a slide."

## 0:30 to 1:30 · Ask what happened overnight

**Click:** the suggested action **"Check overnight issues"**.

**On screen:** six agent steps check off one by one.

**Say while they run:**
> "Watch how it works the problem, the way a good planner would."

**Point at each step as it lands:**
> "The container is held at the port after a local labour incident, and there's no estimate of when it clears.
> So it checks stock at the other distribution centers.
> Reno has 4,800 units against a forecast of 3,360. Regional demand is lagging, so 30% of that stock is excess.
> Before it proposes anything, it prices the freight. A less-than-truckload quote comes in 20% below the typical rate on that lane.
> Only then does it recommend moving 25% of Reno's stock, 1,200 units, to the warehouse that's short."

**Optional:**
> "25% isn't a random number. It's the most the playbook allows without VP approval."

## 1:30 to 2:15 · Review before anything is written

**Click:** the container row, then **Continue**.

**On screen:** the review card, with the LTL quote selected, the follow-up days, the blue locked values and the pre-filled prompt.

**Say:**
> "Before any AI writes anything, Paul sees exactly what it's being asked to do and which numbers it's allowed to use.
> These blue tags are locked: on-hand stock, forecast, units to transfer, pallets, the typical rate, the quote and the saving.
> They come straight from the warehouse and transportation systems.
> The model isn't allowed to improvise a single number."

**Click:** **Generate draft**.

## 2:15 to 3:00 · Draft the transfer order, then try to break it

**On screen:** a transfer order to the Reno DC streams in, then a green tag: "Facts match database".

**Say while it streams:**
> "A transfer order with the reason, the stock check, the freight decision and the next steps.
> It's addressed to the Reno team, with the inbound planner copied."

**When it finishes, edit live:** in the body, change **20%** to **15%**.

**On screen:** a red tag, "Draft says 15%, database says 20% (ltl quote below typical)".

**Say:**
> "Now say someone, human or AI, gets a number wrong.
> The draft is checked against the source systems every time it changes, so the mistake is caught before it reaches the carrier."

**Change it back to 20%.** The tag turns green again.

Use 15%, not 30% or 25%. Those are real facts in this flow, so the check would accept them.

## 3:00 to 3:30 · Approve the transfer

**Click:** **Create transfer order**.

**On screen:** "Transfer order sent to the Reno DC for 1,200 units of PC-CM-1200. Logged to the WMS. LTL booking opened with Transportation. Follow-up task created."

**Say:**
> "One click. The transfer is logged in the warehouse system, the LTL pickup goes to Transportation to book at the quoted rate, and a task reminds Paul to confirm the stock arrived.
> Nothing moved without a person saying yes."

**Click:** **Today's signals** in the side nav.

**On screen:** the held-shipment signal has moved to **Done today**.

**Say:**
> "And it's off Paul's list."

## 3:30 to 4:30 · Resolve the at-risk orders

**Click:** the **"3 customer orders at risk this week"** signal.

**On screen:** "2 of 3 ship complete and qualify for Next-day delivery at no charge". In the table, Harbor Lane Department Stores is tagged **Not eligible**.

**Say:**
> "Fixing the inventory is half the job. Three customers were promised stock from that container, and none of them know yet.
> The assistant allocated the 1,200 transferred units, earliest promise date first.
> Two orders ship complete, so those customers get next-day delivery at no charge and never feel the disruption.
> Harbor Lane is the hard one: 900 units ordered, only 200 available this week."

**Click:** select all three rows, **Continue**, then **Generate 3 drafts**.

**On screen:** three drafts in tabs. Open the **Harbor Lane Department Stores** tab.

**Say:**
> "Look at what it does for Harbor Lane. It doesn't promise what it can't deliver.
> It gives Elena two real choices: 200 units now and the balance next week, or one complete delivery.
> Same facts, same guardrails, a different message for each situation."

**Click:** **Send update (3)**.

## 4:30 to 5:15 · Review the supplier exceptions

**Click:** **Today's signals**, then the **"2 supplier exceptions to review"** signal.

**On screen:** "1 of 2 meet the threshold for a Corrective action request (CAR)". Northwind Packaging is tagged **Not eligible**, Sierra Component Works **Eligible**.

**Say:**
> "Two suppliers missed their commitments, but they don't deserve the same response.
> Northwind shipped 240 cartons short, their first miss in a month. They get a notice and a request for a corrected ASN.
> Sierra delivered 4 days late, their second miss in 30 days, and their on-time rate is 71% against a 95% SLA.
> That pattern is exactly what a busy person misses, and it triggers a formal corrective action request."

**Click:** **Sierra Component Works**, **Continue**, **Generate draft**, then **Send notice**.

## 5:15 to 5:40 · Prove it happened

**Click:** the activity icon in the header.

**On screen:** the transfer order, the LTL booking ticket in Transportation, the three customer updates and the supplier notice, each tagged "This session" and "Facts verified", with the follow-up tasks underneath.

**Say:**
> "This isn't a mock-up. That's the activity log: every action, who approved it, whether the facts were verified, and the follow-ups on Paul's list."

**Press** `Esc` to close the panel.

## 5:40 to 6:00 · Go off-script

**Type** in the chat box: **"How much stock can we transfer between distribution centers?"** and press Enter.

**On screen:** an answer citing the playbook section "Inter-DC inventory transfers (PB-I-012)": up to 25% of on-hand stock without VP approval.

**Say:**
> "And when Paul wants to check a rule, he just asks.
> The answer comes from the company's own playbook, with the section it came from."

**If time allows (live mode only):** ask **"When will the container clear the port?"**
The assistant says the port has given no clearance estimate instead of inventing one.
> "And when it doesn't know, it says so."

**Close:**
> "A container got stuck overnight.
> Before Paul finished his coffee, the stock was found, the freight was priced, the transfer was approved, the customers were told and the supplier was held to account.
> The AI did the legwork. Paul made every decision that mattered."

## If something goes wrong

| Problem | What to do |
|---|---|
| Wi-Fi drops mid-draft | Nothing. If no token arrives within 12 seconds, the offline text streams instead and the dot turns gray. |
| A signal is already in "Done today" | You ran it in rehearsal. Click empty space, then `Shift+R`. |
| The fact check stays green after your edit | You typed a number that is a real fact in this flow (30% or 25%). Use 15%. |
| A shortcut types a letter instead | The cursor was in a text field. Click empty space and press it again. |
| The live model wanders off topic | Press `Regenerate`, or `Shift+O` for the pre-approved offline draft. |
| Short on time | Skip the supplier section (4:30 to 5:15). The story still holds. |
