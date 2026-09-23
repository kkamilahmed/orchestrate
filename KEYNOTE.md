# Keynote script: Insurance (5 minutes)

Persona: **Paul Zikopoulos**, Senior Account Manager at **Harborline Mutual Insurance**.
The story: AI notices the moment, drafts the busywork, and Paul stays in control.

## Before you go on stage

1. Start the database, the API and the web app (see README), then open http://localhost:3000 at 1920x1080.
2. Click an empty area of the page, then press `Shift+I` and `1` to make sure you're on Insurance.
3. Press `Shift+R` to reset, so the activity panel only shows seeded history.
4. Check the dot at the far right of the header.
Green means live, gray means offline.
If the Wi-Fi is doubtful, press `Shift+O` now; offline looks identical.
5. Keep the cursor out of text fields whenever you use a shortcut.

## 0:00 to 0:30 · Open on the signals

**On screen:** the home screen, "Good morning, Paul" and four signals.

**Say:**
> "This is Paul's morning. No blank chat box, no blinking cursor.
> Overnight, the assistant went through Paul's book of business and found what actually needs attention today.
> Five clients had life events this week. Three of their kids just aged out of the family plan. Two policies renew in the next two weeks.
> These numbers aren't made up for the slide. They're live queries against the CRM database."

## 0:30 to 1:15 · Let the agent work

**Click:** the first signal, **"5 clients had life events this week"**.

**On screen:** the agent steps check off one by one: "Found 5 clients...", "4 of 5 qualify for the 15% loyalty discount".

**Say:**
> "Watch what it does: it queries the CRM, finds the five clients, and checks each one against our eligibility rules.
> Four of the five qualify for the loyalty discount. One doesn't, and the assistant already knows that."

**Point at:** the table, where Linda Park is tagged "Not eligible" because she's been a client for one year.

## 1:15 to 1:45 · Select a client

**Click:** the **John Collins** row, then **Continue**.

**Say:**
> "John's son Ethan turned 25 this week. On our family plans, that means Ethan loses coverage at the end of the month.
> That's exactly the kind of moment a great account manager catches, and a busy one misses."

## 1:45 to 2:30 · Review the prompt

**On screen:** the review card, with the product dropdown, follow-up days, blue "locked values" tags and the pre-filled prompt.

**Say:**
> "Before anything is written, Paul sees exactly what we're asking the AI to do.
> The prompt comes from a template and is filled in with real data: Ethan's age, John's nine years with us, the Silver plan, $412 a month.
> These blue tags are locked values. The discount, the price, the age come straight from the database.
> The AI isn't allowed to improvise on numbers."

**Optional:** point at the product dropdown.
> "To offer the Gold plan instead, Paul changes it here and the prompt updates."

**Click:** **Generate draft**.

## 2:30 to 3:15 · Stream the draft, then edit it live

**On screen:** the email types itself out, then a green tag appears: "Facts match database (3 checked)".

**Say while it streams:**
> "To, cc, subject are filled in. And the body is written for John, about Ethan, in plain language."

**When it finishes, edit live:** click into the body and change **15%** to **20%**.

**On screen:** a red tag, "Fact check: 1 mismatch" and "Draft says 20%, database says 15% (loyalty discount)".

**Say:**
> "Now say someone, human or AI, gets generous with the discount.
> The draft is checked against the database every time it changes. 20% isn't a number we offer, so it's flagged immediately."

**Change it back to 15%.** The tag turns green again.

**Optional personal touch:** add a line such as "P.S. Congratulations to Ethan!" before the sign-off.
> "And of course Paul can make it personal."

## 3:15 to 3:45 · Approve

**Click:** **Send email**.

**On screen:** "Email sent to John Collins. Logged to CRM. Follow-up task created for Friday."

**Say:**
> "One click. The email is logged to the CRM, and a follow-up task is on Paul's calendar for Friday.
> Nothing left the building without a human saying yes."
> (Emails are simulated in this demo.)

## 3:45 to 4:15 · Prove it happened

**Click:** **View activity** (or the activity icon in the header).

**On screen:** the activity panel, with "Email sent to John Collins" (tagged "This session" and "Facts verified") and the follow-up task underneath.

**Say:**
> "This isn't a mock-up. That's the activity log in the database: the email, who approved it, that the facts were verified, and the task for Friday."

**Press** `Esc` to close the panel.

## 4:15 to 5:00 · Go off-script

**Type** in the chat box: **"Which client should I call first today?"** and press Enter.

**On screen:** a ranked answer, with John Collins first (hard deadline), Tom Walsh second (his claim is 34 days old, past the 21-day standard) and Robert Chen third (his bundle renews in 9 days).

**Say:**
> "And to think out loud, Paul just asks.
> The assistant answers from the same data, the clients, their events and the handbook, so the answer is grounded, not generic."

**If time allows (live mode):** ask **"What does the loyalty discount require?"**
The answer cites the handbook section it came from, as a blue tag and a sources card.

**Close:**
> "The AI noticed the moment, did the busywork, and checked its own numbers.
> Paul made every decision that mattered."

## If something goes wrong

| Problem | What to do |
|---|---|
| Wi-Fi drops mid-draft | Nothing. If no token arrives within 12 seconds, the offline text streams instead and the dot turns gray. |
| You want to rehearse or restart | Click empty space, then `Shift+R`. |
| A shortcut types a letter instead | The cursor was in a text field. Click empty space and press it again. |
| The live model wanders off topic | Press `Regenerate`, or `Shift+O` for the pre-approved offline draft. |
| Presenting to a different audience | `Shift+I` switches to Banking, Healthcare, Retail, HR, Real estate or Manufacturing. Every industry has the same flow shape. |
