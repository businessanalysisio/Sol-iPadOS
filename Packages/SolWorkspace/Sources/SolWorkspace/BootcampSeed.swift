import Foundation
import SolStore

/// Seed content "BA Bootcamp" — the SOL Bootcamp OS production workbook
/// (Read Me · Backlog · Sprint Plan · Dashboard) installed into a fresh
/// workspace, so first launch shows the analyst's real working set instead
/// of an empty S1 (mockup v3.1 sidebar: 📁 BA Bootcamp).
///
/// The documents are plain `.md` + `sol-data` fences — everything renders
/// through the normal M2/M3 pipeline (no special-casing in editor/preview).
/// Data source: BA_Bootcamp_Production_Backlog workbook (Drive, 2026-07-20).
public enum BootcampSeed {
    /// Hidden marker in the workspace root — DocumentStore only lists `*.md`,
    /// so it never shows up as a document. Presence = "already seeded":
    /// a user who deletes the seed docs must NOT see them resurrected on
    /// the next launch (same spirit as APP-NFR-02: user intent wins).
    public static let markerName = ".sol-seed-bootcamp-v1"

    /// Installs the seed set once per workspace. Returns true when the
    /// documents were installed by this call.
    @discardableResult
    public static func installIfNeeded(into store: DocumentStore) throws -> Bool {
        let marker = store.root.appendingPathComponent(markerName)
        guard !FileManager.default.fileExists(atPath: marker.path) else { return false }
        for doc in documents {
            try store.createDocument(named: doc.name, contents: doc.body)
        }
        try Data().write(to: marker)
        return true
    }

    /// Titles share the "BA Bootcamp — " prefix so the set groups together
    /// in the flat M1 workspace (folders are post-v1; the mockup's
    /// 📁 BA Bootcamp maps to this prefix for now).
    public static let documents: [(name: String, body: String)] = [
        (name: "BA Bootcamp — 00 · Read Me", body: readMe),
        (name: "BA Bootcamp — 01 · Backlog", body: backlog),
        (name: "BA Bootcamp — 02 · Sprint Plan", body: sprintPlan),
        (name: "BA Bootcamp — 03 · Dashboard", body: dashboard),
    ]

    // MARK: - 00 · Read Me

    static let readMe = """
    # BA Bootcamp — Production Backlog

    Course materials + sales collateral, sequenced into production sprints.

    ## How to use this workbook

    | Tài liệu | Vai trò |
    | --- | --- |
    | Backlog | The master list of every work item. Filter by Track, Epic, Priority, Sprint, or Status. |
    | Sprint Plan | The same work laid out on a timeline — sprint goals, dates, effort, and key outputs. |
    | Dashboard | Live counts & effort roll-ups by track, sprint, and priority. |

    Update as you go: change the Status column on the Backlog; the Dashboard follows.

    ## Legend

    ### Priority (MoSCoW)

    | Mức | Ý nghĩa |
    | --- | --- |
    | Must | Ships-blocker — the launch cannot happen without it |
    | Should | High value — include unless time forces a cut |
    | Could | Nice-to-have — do if capacity allows |

    ### Effort & Status

    - Effort (days): person-days of production/prep effort (not calendar time). Facilitating the beta is estimated separately.
    - Status values: Not started · In progress · Blocked · Done

    ## Team roles

    | Role | Mô tả |
    | --- | --- |
    | Course Lead | You (Sol) — subject-matter expert, on-camera, final sign-off |
    | ID | Instructional Designer — scripting support, rubrics, learning flow |
    | Designer | Brand, slides, templates, sales-page & content visuals |
    | Video Editor | Recording setup, editing, captions, QA |
    | Marketer | Copy, funnel, email, ads, launch |
    | Tech | LMS, checkout, integrations, sandbox (freelance/contract) |

    ## Sprint schedule (suggested)

    | Sprint | Focus | Dates (2026) |
    | --- | --- | --- |
    | S0 · Foundations | Strategy, offer, brand, platform, waitlist | Jul 20 – Jul 31 |
    | S1 · Core Build I | Modules 1–2 + lead magnet + nurture | Aug 3 – Aug 14 |
    | S2 · Core Build II | Module 3 + sales page + webinar/ads | Aug 17 – Aug 28 |
    | S3 · Complete Build | Modules 4–5 + LMS + beta prep + launch assets | Aug 31 – Sep 11 |
    | Beta Cohort | Deliver live, gather feedback & testimonials | Sep 14 – Dec 4 |
    | S4 · Iterate & Launch | Fix friction, finalize, public launch | Dec 7 – Dec 18 |
    """

    // MARK: - 01 · Backlog (67 items — Course Materials 35 · Sales & Marketing 25 · Validation & Launch 7)

    static let backlog = """
    # BA Bootcamp — Backlog

    Master list — 67 items · 169 person-days. Priority theo MoSCoW, effort tính bằng person-days.

    ## Course Materials (35 items · 89d)

    | ID | Epic | Item | Definition of Done | Type | Owner | Priority | Effort (d) | Depends on | Sprint | Status |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | CM-01 | Instructional Design & Scripting | Master content style guide & lesson template | Reusable Why/What/How/Action lesson template + tone/style guide approved | Doc/Template | Course Lead + ID | Must | 2 | — | S0 · Foundations | Not started |
    | CM-02 | Instructional Design & Scripting | Script Module 1 (Wk 1–2) lessons | Full scripts for Foundations & Business Thinking lessons, reviewed | Scripts | Course Lead + ID | Must | 3 | CM-01 | S1 · Core Build I | Not started |
    | CM-03 | Instructional Design & Scripting | Script Module 2 (Wk 3–5) lessons | Full scripts for Discovery & Requirements, reviewed | Scripts | Course Lead + ID | Must | 4 | CM-01 | S1 · Core Build I | Not started |
    | CM-04 | Instructional Design & Scripting | Script Module 3 (Wk 6–8) lessons | Full scripts for Analysis & Solution Design (incl. SQL), reviewed | Scripts | Course Lead + ID | Must | 4 | CM-01 | S2 · Core Build II | Not started |
    | CM-05 | Instructional Design & Scripting | Script Module 4 (Wk 9–10) lessons | Full scripts for Implementation, Data & Validation, reviewed | Scripts | Course Lead + ID | Must | 3 | CM-01 | S3 · Complete Build | Not started |
    | CM-06 | Instructional Design & Scripting | Script Module 5 (Wk 11–12) lessons | Full scripts for Capstone & Career Launch, reviewed | Scripts | Course Lead + ID | Must | 3 | CM-01 | S3 · Complete Build | Not started |
    | CM-07 | Slide Decks & Visual Assets | Brand & slide template system | Master deck, diagram/process-map style, reusable layouts | Design System | Designer | Must | 3 | CM-01 | S0 · Foundations | Not started |
    | CM-08 | Slide Decks & Visual Assets | Module 1 slide deck | Designed deck matching scripts, visuals over text | Slides | Designer | Must | 2 | CM-07, CM-02 | S1 · Core Build I | Not started |
    | CM-09 | Slide Decks & Visual Assets | Module 2 slide deck | Designed deck for requirements lessons | Slides | Designer | Must | 2 | CM-07, CM-03 | S1 · Core Build I | Not started |
    | CM-10 | Slide Decks & Visual Assets | Module 3 slide deck (process/data) | Designed deck, heavy on BPMN & data visuals | Slides | Designer | Must | 3 | CM-07, CM-04 | S2 · Core Build II | Not started |
    | CM-11 | Slide Decks & Visual Assets | Module 4 slide deck | Designed deck for Agile/testing lessons | Slides | Designer | Must | 2 | CM-07, CM-05 | S3 · Complete Build | Not started |
    | CM-12 | Slide Decks & Visual Assets | Module 5 slide deck | Designed deck for capstone & career prep | Slides | Designer | Must | 2 | CM-07, CM-06 | S3 · Complete Build | Not started |
    | CM-13 | Templates & Prompt Packs | Template system design | Naming, file format, folder structure & versioning for all student templates | Spec | ID + Designer | Should | 1 | CM-01 | S0 · Foundations | Not started |
    | CM-14 | Templates & Prompt Packs | Foundations templates | Stakeholder map, RACI, influence/interest grid, positioning one-pager | Templates | Designer + ID | Must | 2 | CM-13 | S1 · Core Build I | Not started |
    | CM-15 | Templates & Prompt Packs | Requirements templates | Elicitation plan, interview guide, BRD, user-story backlog, traceability matrix | Templates | ID | Must | 3 | CM-13 | S1 · Core Build I | Not started |
    | CM-16 | Templates & Prompt Packs | Design templates | BPMN/swimlane starter, wireframe kit, functional spec template | Templates | Designer + ID | Must | 3 | CM-13 | S2 · Core Build II | Not started |
    | CM-17 | Templates & Prompt Packs | Data & validation templates | Data dictionary, SQL query workbook, UAT plan, test-case sheet, Gherkin cheat-sheet | Templates | ID | Must | 3 | CM-13 | S3 · Complete Build | Not started |
    | CM-18 | Templates & Prompt Packs | AI Copilot prompt packs (12) | One prompt pack per week so students never start blank | Prompt Packs | Course Lead + ID | Should | 3 | CM-01 | S2 · Core Build II | Not started |
    | CM-19 | Video/Audio Production | Recording setup & standards | Studio, lighting, audio, screen-capture workflow documented & tested | Process/Setup | Video Editor | Must | 1 | — | S0 · Foundations | Not started |
    | CM-20 | Video/Audio Production | Record Module 1–2 lessons | All Wk 1–5 lessons recorded to standard | Raw Video | Course Lead + Video | Must | 3 | CM-08, CM-09, CM-19 | S1 · Core Build I | Not started |
    | CM-21 | Video/Audio Production | Record Module 3 lessons | All Wk 6–8 lessons recorded (incl. SQL screen-share) | Raw Video | Course Lead + Video | Must | 3 | CM-10 | S2 · Core Build II | Not started |
    | CM-22 | Video/Audio Production | Record Module 4–5 lessons | All Wk 9–12 lessons recorded | Raw Video | Course Lead + Video | Must | 4 | CM-11, CM-12 | S3 · Complete Build | Not started |
    | CM-23 | Video/Audio Production | Edit & QA Module 1–2 videos | Cut, captioned, quality-checked, uploaded | Final Video | Video Editor | Must | 3 | CM-20 | S2 · Core Build II | Not started |
    | CM-24 | Video/Audio Production | Edit & QA Module 3 videos | Cut, captioned, quality-checked, uploaded | Final Video | Video Editor | Must | 2 | CM-21 | S2 · Core Build II | Not started |
    | CM-25 | Video/Audio Production | Edit & QA Module 4–5 videos | Cut, captioned, quality-checked, uploaded | Final Video | Video Editor | Must | 3 | CM-22 | S3 · Complete Build | Not started |
    | CM-26 | Capstone & Assessment | Capstone case scenario + dataset | Realistic scenario brief + supporting data (retail/clinic) | Case Assets | Course Lead + ID | Must | 3 | CM-01 | S2 · Core Build II | Not started |
    | CM-27 | Capstone & Assessment | SQL sandbox + guided exercises | Working sample DB students can query, with graded exercises | Sandbox | Tech + ID | Should | 3 | CM-26 | S2 · Core Build II | Not started |
    | CM-28 | Capstone & Assessment | Capstone brief, rubric & sample solution | Student brief, grading rubric, and reference solution | Docs | ID + Course Lead | Must | 2 | CM-26 | S3 · Complete Build | Not started |
    | CM-29 | Capstone & Assessment | Weekly assignment rubrics & feedback guides | Rubric + feedback prompts for each weekly deliverable | Docs | ID | Should | 2 | CM-15, CM-16, CM-17 | S3 · Complete Build | Not started |
    | CM-30 | LMS & Cohort Ops | Select & configure LMS/platform | Platform chosen, billing, roles & branding configured | Platform | Tech | Must | 2 | — | S0 · Foundations | Not started |
    | CM-31 | LMS & Cohort Ops | Build course shell | Modules, lessons, drip schedule, uploads wired in LMS | Platform Build | Tech | Must | 3 | CM-30, CM-23 | S3 · Complete Build | Not started |
    | CM-32 | LMS & Cohort Ops | Community/cohort space setup | Slack/Circle/Discord configured with channels & rules | Community | Tech + Course Lead | Must | 1 | — | S3 · Complete Build | Not started |
    | CM-33 | LMS & Cohort Ops | Live session system & cadence | Zoom, calendar, recurring invites, session agendas | Process | Course Lead | Must | 1 | — | S3 · Complete Build | Not started |
    | CM-34 | LMS & Cohort Ops | Student onboarding flow | Welcome sequence, orientation, week-0 checklist | Onboarding | ID + Marketer | Must | 2 | CM-31, CM-32 | S3 · Complete Build | Not started |
    | CM-35 | LMS & Cohort Ops | Student workbook/handbook | Compiled PDF of all templates & instructions | Workbook | ID + Designer | Should | 3 | CM-14, CM-15, CM-16, CM-17 | S3 · Complete Build | Not started |

    ## Sales & Marketing (25 items · 50d)

    | ID | Epic | Item | Definition of Done | Type | Owner | Priority | Effort (d) | Depends on | Sprint | Status |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | SM-01 | Brand, Positioning & Offer | Offer design & pricing | Tiers, price points, guarantee, bonuses defined & validated | Strategy | Course Lead + Marketer | Must | 2 | — | S0 · Foundations | Not started |
    | SM-02 | Brand, Positioning & Offer | Positioning & messaging doc | Big idea, promise, objections, proof, angles | Messaging | Marketer | Must | 2 | SM-01 | S0 · Foundations | Not started |
    | SM-03 | Brand, Positioning & Offer | Brand identity kit | Logo, colors, fonts, brand voice (shared with course visuals) | Brand Kit | Designer | Must | 2 | — | S0 · Foundations | Not started |
    | SM-04 | Brand, Positioning & Offer | Competitive & pricing research | Landscape of comparable BA courses, pricing, gaps | Research | Marketer | Should | 1 | — | S0 · Foundations | Not started |
    | SM-05 | Lead Generation | Lead magnet (BA Starter Kit) | Free template pack/guide + delivery, matches offer | Lead Magnet | Course Lead + Marketer + Designer | Must | 3 | SM-02, CM-14 | S1 · Core Build I | Not started |
    | SM-06 | Lead Generation | Waitlist / opt-in landing page | Live page capturing emails, connected to email tool | Landing Page | Marketer + Tech | Must | 2 | SM-02 | S1 · Core Build I | Not started |
    | SM-07 | Lead Generation | Free masterclass / webinar | Slides + script for a value-first live/evergreen class | Webinar | Course Lead + Marketer | Should | 3 | SM-02 | S2 · Core Build II | Not started |
    | SM-08 | Lead Generation | Readiness quiz / assessment | Interactive 'Are you ready to be a BA?' lead capture | Quiz | Marketer | Could | 2 | SM-06 | S2 · Core Build II | Not started |
    | SM-09 | Sales Page & Funnel | Long-form sales page copy | Full sales copy: promise, modules, proof, offer, FAQ | Copy | Marketer | Must | 3 | SM-01, SM-02 | S2 · Core Build II | Not started |
    | SM-10 | Sales Page & Funnel | Sales page design & build | Designed, responsive, published sales page | Web Page | Designer + Tech | Must | 3 | SM-09 | S2 · Core Build II | Not started |
    | SM-11 | Sales Page & Funnel | VSL (video sales letter) | Script + recorded + edited sales video on page | Video | Course Lead + Marketer + Video | Should | 3 | SM-09 | S2 · Core Build II | Not started |
    | SM-12 | Sales Page & Funnel | Checkout & enrollment flow | Payment, tax, receipts, enrollment tested end-to-end | Commerce | Tech | Must | 2 | SM-10, CM-30 | S2 · Core Build II | Not started |
    | SM-13 | Sales Page & Funnel | FAQ & objection handling | Objection-handling section + refund/guarantee copy | Copy | Marketer | Should | 1 | SM-09 | S2 · Core Build II | Not started |
    | SM-14 | Email Marketing | Email platform setup | ESP configured, list, tags, automations scaffolded | Setup | Marketer + Tech | Must | 1 | — | S1 · Core Build I | Not started |
    | SM-15 | Email Marketing | Welcome / nurture sequence | 5–7 email nurture that follows the lead magnet | Emails | Marketer | Must | 2 | SM-05, SM-14 | S1 · Core Build I | Not started |
    | SM-16 | Email Marketing | Launch / cart sequence | Open-cart, value, urgency, close emails written & scheduled | Emails | Marketer | Must | 2 | SM-09 | S3 · Complete Build | Not started |
    | SM-17 | Email Marketing | Post-purchase onboarding emails | Buyer welcome + access + expectations emails | Emails | Marketer | Should | 1 | SM-12, CM-34 | S3 · Complete Build | Not started |
    | SM-18 | Content & Social Proof | Organic content plan | Channel plan + topic calendar (LinkedIn/YT/short-form) | Plan | Marketer + Course Lead | Should | 2 | SM-02 | S1 · Core Build I | Not started |
    | SM-19 | Content & Social Proof | Content asset batch | First batch of posts, carousels, shorts produced | Content | Marketer + Designer | Should | 3 | SM-18 | S2 · Core Build II | Not started |
    | SM-20 | Content & Social Proof | Testimonial capture system | Process + forms to collect results & testimonials | Process | Marketer | Must | 1 | — | S3 · Complete Build | Not started |
    | SM-21 | Content & Social Proof | Beta testimonials → collateral | Quotes, video clips, before/after results packaged | Social Proof | Marketer + Video | Must | 2 | SM-20, V-03 | S4 · Iterate & Launch | Not started |
    | SM-22 | Paid Ads & Launch | Ad creative & copy | Lead-magnet + webinar ad creatives and variants | Ads | Marketer + Designer | Should | 2 | SM-05, SM-07 | S2 · Core Build II | Not started |
    | SM-23 | Paid Ads & Launch | Ad setup & tracking | Pixels, UTM, conversions, dashboards configured | Setup | Marketer + Tech | Should | 2 | SM-06, SM-22 | S2 · Core Build II | Not started |
    | SM-24 | Paid Ads & Launch | Launch campaign plan & calendar | Channel-by-channel launch timeline & responsibilities | Plan | Marketer | Must | 2 | SM-09, SM-15 | S3 · Complete Build | Not started |
    | SM-25 | Paid Ads & Launch | Affiliate / partner outreach kit | Partner one-pager, swipe copy, tracking links | Kit | Marketer | Could | 1 | SM-02 | S3 · Complete Build | Not started |

    ## Validation & Launch (7 items · 30d)

    | ID | Epic | Item | Definition of Done | Type | Owner | Priority | Effort (d) | Depends on | Sprint | Status |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | V-01 | Beta Cohort & Iteration | Recruit beta cohort (5–10) | Beta students enrolled at discount for honest feedback | Recruitment | Course Lead + Marketer | Must | 2 | SM-05, SM-06 | S3 · Complete Build | Not started |
    | V-02 | Beta Cohort & Iteration | Deliver beta cohort (live, JIT) | Run the 12-week cohort, building just ahead as needed | Delivery | Course Lead | Must | 15 | CM-31, CM-32, CM-33, V-01 | Beta Cohort | Not started |
    | V-03 | Beta Cohort & Iteration | Collect feedback & friction data | Track drop-off/questions esp. Wk 5, 8, 9; synthesize | Analysis | Course Lead + ID | Must | 3 | V-02 | Beta Cohort | Not started |
    | V-04 | Beta Cohort & Iteration | Rewrite friction sections | Add explainers / re-record where beta struggled | Revisions | Course Lead + ID + Video | Must | 4 | V-03 | S4 · Iterate & Launch | Not started |
    | V-05 | Beta Cohort & Iteration | Finalize evergreen recordings & LMS | Polished v1.0 course fully loaded and tested | Final Build | Video + Tech | Should | 3 | V-04 | S4 · Iterate & Launch | Not started |
    | V-06 | Beta Cohort & Iteration | Public launch execution | Cart opens; campaign live; sales tracked | Launch | Marketer + Course Lead | Must | 2 | SM-16, SM-24, V-04 | S4 · Iterate & Launch | Not started |
    | V-07 | Beta Cohort & Iteration | Post-launch retro & v1.1 backlog | Retro doc + prioritized improvements for next cohort | Doc | Course Lead + ID | Should | 1 | V-06 | S4 · Iterate & Launch | Not started |
    """

    // MARK: - 02 · Sprint Plan

    static let sprintPlan = """
    # BA Bootcamp — Sprint Plan

    ## Timeline 2026

    | Sprint | Dates (2026) | Sprint Goal | Key Outputs | Items | Effort (d) |
    | --- | --- | --- | --- | --- | --- |
    | S0 · Foundations | Jul 20 – Jul 31 | Lock strategy & foundations so every later build has a spec. | Style guide, brand/slide system, offer & pricing, messaging, LMS chosen, waitlist live | 9 | 16 |
    | S1 · Core Build I | Aug 3 – Aug 14 | Build the front half of the course and switch on lead capture. | Modules 1–2 scripted/designed/recorded, core templates, lead magnet, nurture emails | 12 | 29 |
    | S2 · Core Build II | Aug 17 – Aug 28 | Build the technical core and stand up the sales funnel. | Module 3 + SQL sandbox + capstone case, sales page, VSL, webinar, ads, edited M1–3 video | 19 | 51 |
    | S3 · Complete Build | Aug 31 – Sep 11 | Finish all content and everything needed to run a cohort. | Modules 4–5, LMS shell, community, onboarding, launch/cart sequence, beta recruited | 20 | 43 |
    | Beta Cohort | Sep 14 – Dec 4 | Prove the course with real students and capture proof. | Live delivery, friction data (Wk 5/8/9), testimonials & results | 2 | 18 |
    | S4 · Iterate & Launch | Dec 7 – Dec 18 | Fix what beta exposed and open to the public. | Reworked friction sections, evergreen v1.0, testimonial collateral, public launch | 5 | 12 |
    | TOTAL | | | | 67 | 169 |

    ## Effort theo sprint

    ```sol-data type=bar title="Effort (person-days) theo sprint"
    sprint,days
    S0 · Foundations,16
    S1 · Core Build I,29
    S2 · Core Build II,51
    S3 · Complete Build,43
    Beta Cohort,18
    S4 · Iterate & Launch,12
    ```

    ## Số item theo sprint

    ```sol-data type=bar title="Số backlog item theo sprint"
    sprint,items
    S0 · Foundations,9
    S1 · Core Build I,12
    S2 · Core Build II,19
    S3 · Complete Build,20
    Beta Cohort,2
    S4 · Iterate & Launch,5
    ```
    """

    // MARK: - 03 · Dashboard

    static let dashboard = """
    # BA Bootcamp — Production Dashboard

    Roll-up từ Backlog (67 items · 169 person-days). Trạng thái hiện tại: chưa bắt đầu (0% done).

    ## By track

    | Track | Items | Effort (days) | % Done |
    | --- | --- | --- | --- |
    | Course Materials | 35 | 89 | 0% |
    | Sales & Marketing | 25 | 50 | 0% |
    | Validation & Launch | 7 | 30 | 0% |
    | TOTAL | 67 | 169 | 0% |

    ```sol-data type=bar title="Effort (days) theo track"
    track,days
    Course Materials,89
    Sales & Marketing,50
    Validation & Launch,30
    ```

    ## By priority (MoSCoW)

    | Priority | Items | Effort (days) |
    | --- | --- | --- |
    | Must | 49 | 132 |
    | Should | 16 | 34 |
    | Could | 2 | 3 |

    ```sol-data type=pie title="Effort (days) theo priority"
    priority,days
    Must,132
    Should,34
    Could,3
    ```

    ## By sprint

    | Sprint | Items | Effort (days) | % Done |
    | --- | --- | --- | --- |
    | S0 · Foundations | 9 | 16 | 0% |
    | S1 · Core Build I | 12 | 29 | 0% |
    | S2 · Core Build II | 19 | 51 | 0% |
    | S3 · Complete Build | 20 | 43 | 0% |
    | Beta Cohort | 2 | 18 | 0% |
    | S4 · Iterate & Launch | 5 | 12 | 0% |

    ```sol-data type=line title="Effort (days) theo sprint"
    sprint,days
    S0 · Foundations,16
    S1 · Core Build I,29
    S2 · Core Build II,51
    S3 · Complete Build,43
    Beta Cohort,18
    S4 · Iterate & Launch,12
    ```
    """
}
