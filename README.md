# AI Workforce Odyssey

**An agent-based simulation of how workers adapt when AI automation accelerates — and why equal access to training does not produce equal recovery.**

*Built solo in NetLogo for CMU Heinz College's Agentic Technologies (Spring 2026), with AI coding assistance.*

**Result:** with identical access to training, 9 of 30 workers ended unemployed under Tech-Driven automation versus 1 under Human-Centric support (one run per scenario).

**[▶ Run the model in your browser](https://www.netlogoweb.org/launch#https://raw.githubusercontent.com/asligulcur/AI_Workforce_Odyssey_2026/main/AI_Workforce_Odyssey.nlogo)** (NetLogo Web, no install): click **Tech-Driven** or **Human-Centric**, then **Setup** and **Go**.

---

## The question

When AI disrupts a labor market, do workers who get the same access to retraining end up in the same place?

## The model

- **30 workers** in one labor market, simulated over **75 monthly ticks** of steadily rising automation pressure.
- **4 task types** with different AI exposure: routine-cognitive (data entry, bookkeeping), non-routine cognitive (analysis, design), relationship-based (sales, partnerships) and non-routine manual (care work, trades).
- **3 seniority levels** (junior workers face higher disruption risk) and **2 behavioral traits**: *adaptability* (who enters and benefits from training) and *resilience* (who disengages under pressure).
- **5 states:** Employed → At-Risk → In-Training → Recovered (re-employed or AI-augmented), or Unemployed.
- **7 programmed transition rules:** threshold-based disruption, probabilistic training entry, timeouts, training completion, re-entry with "scarring", a disgruntled path for low-resilience workers, and re-risk for recovered workers.
- **Interaction mechanisms:** peer influence from nearby recovered or training workers, disgruntled contagion, scarring (the longer someone is unemployed, the less adaptable they become) and a cap on training seats.

Disruption risk = 0.50 × routine share + 0.30 × automation pressure (normalized) + 0.20 × seniority penalty.

![State transition diagram](figures/state_transition_diagram.png)

*States, the seven transition rules, the emergent mechanisms and both scenarios' parameters.*

## Two scenarios, same code

- **Tech-Driven Automation:** AI is adopted aggressively and workers get little support: fewer and longer training programs, less chance of moving into AI-augmented work, and quicker layoffs.
- **Human-Centric Support:** AI is adopted more selectively and workers get strong support: more and shorter training, better odds of AI-augmented work, and more time before layoffs.

| Parameter | Tech-Driven Automation | Human-Centric Support |
|---|---|---|
| Base pressure / acceleration | 10 / 0.40 per tick | 5 / 0.20 per tick |
| Disruption threshold | 0.50 | 0.55 |
| Training seats / duration | 8 seats / 8 ticks | 20 seats / 5 ticks |
| Augmentation probability | 30% | 55% |
| At-risk / disgruntled timeout | 6 / 8 ticks | 10 / 12 ticks |
| Peer influence radius | 2 patches | 4 patches |
| Scarring rate | 0.5 / tick | 0.3 / tick |

**Note on automation pressure:** the model scores each worker's pressure as a share of that scenario's own maximum. Both scenarios start at 25% of their maximum and rise in step to 100%, so in practice workers feel the same pressure in both. What makes disruption arrive later under Human-Centric support is its higher risk threshold: a worker's risk must reach 0.55 before they become at-risk, versus 0.50 under Tech-Driven automation.

## Results at tick 75

| Metric | Tech-Driven | Human-Centric |
|---|---|---|
| Employed | 6 | 8 |
| At-risk | 3 | 3 |
| In training | 7 | 12 |
| **Unemployed** | **9** | **1** |
| Recovered | 5 | 6 |
| Augmented (share of all 30 workers) | 6.7% | 10% |
| Average time unemployed | 10.6 ticks | 5.3 ticks |
| Training seats still available | 1 | 8 |

*One run per scenario. To reproduce these exact numbers, open the model fresh in NetLogo Web and run Tech-Driven first, then Human-Centric. Later runs give different numbers because worker traits and transitions are random.*

*Charts are from a separate run than the table above, so the numbers differ slightly.*

**Unemployment over time** — Tech-Driven (left) vs Human-Centric (right)

<p>
<img src="figures/unemployment_tech_driven.png" width="45%"> <img src="figures/unemployment_human_centric.png" width="45%">
</p>

**Recovery by task type** — Tech-Driven (top) vs Human-Centric (bottom). RC = routine-cognitive, NRC = non-routine cognitive, RB = relationship-based, NRM = non-routine manual.

<img src="figures/recovery_by_task_tech_driven.png" width="80%">
<img src="figures/recovery_by_task_human_centric.png" width="80%">

## Emergent behavior (not programmed)

- **Adaptation inequality.** Workers with identical training access diverged: some recovered quickly, others became trapped.
- **Unemployment traps.** Scarring created a feedback loop — longer unemployment, lower adaptability, lower re-entry — leaving a persistent tail of unemployed routine-cognitive juniors under Tech-Driven automation.
- **Recovery and stagnation clusters.** Peer effects produced pockets of recovery near early recoverers and stagnation where no one had recovered.
- **Queue amplification under stress.** Training seats were deliberately a *secondary* constraint. They never bound under Human-Centric support (8 seats still free at the end) and bound only during peak disruption waves under Tech-Driven automation.

**Finding:** the 9-vs-1 unemployment gap is not simply about training seats. Under Human-Centric support, 8 of the 20 seats were still empty at the end; under Tech-Driven automation, the 8 seats filled up only during peak disruption waves. The gap reflects the other settings combined: disruption arriving later (a higher threshold), more time before at-risk workers become unemployed, shorter training, less damage from long unemployment, and wider peer support. Because the scenarios change these together, the model cannot isolate which matters most.

**Who recovered, and for how long:** workers in routine office jobs (data entry, bookkeeping) were hit first and retrained first, but as AI pressure kept rising their new jobs were disrupted again. By the end, none of them were still in recovered jobs in either scenario. Workers in less routine jobs were hit later. Under Human-Centric support, more of them recovered and most stayed recovered to the end; under Tech-Driven automation, few recovered at all.

## Run it

**In the browser (no install):** [Open the model in NetLogo Web](https://www.netlogoweb.org/launch#https://raw.githubusercontent.com/asligulcur/AI_Workforce_Odyssey_2026/main/AI_Workforce_Odyssey.nlogo). It runs in your browser with nothing to install.

**Desktop:** install [NetLogo 6.4](https://ccl.northwestern.edu/netlogo/download.shtml) and open `AI_Workforce_Odyssey.nlogo`.

Then click **Tech-Driven** or **Human-Centric** to load a scenario's parameters, **Setup**, then **Go**. Every parameter is exposed as a slider. Colors: green = employed, yellow = at-risk, orange = disgruntled, blue = in training, red = unemployed, white = re-employed, cyan = augmented. Shapes: circle = junior, square = mid, triangle = senior.

## Repository

| Path | Contents |
|---|---|
| `AI_Workforce_Odyssey.nlogo` | The model (NetLogo 6.4.0) |
| `docs/Memo.pdf` | Analysis memo: design, emergent mechanisms, scenario results, reflection |
| `docs/Design_Choices.pdf` | Every significant design choice and its rationale (iterated v1 → v3.2) |
| `docs/State_Transition_Diagram.pdf` | States, transition rules, emergent mechanisms and scenario parameters |
| `figures/` | Charts from the memo and the state diagram |

## Limitations

Workers are the only agents (firm strategy and policy are scenario parameters). The population is fixed at 30 with no entry or exit, spatial proximity stands in for professional networks, and parameters were tuned through test runs rather than calibrated to empirical data. Design concepts — accelerating pressure and junior-worker vulnerability — are informed by Stanford Digital Economy Lab research (see Reference).

## Reference

Brynjolfsson, E., Chandar, B., & Chen, R. *[Canaries in the Coal Mine? Six Facts about the Recent Employment Effects of Artificial Intelligence](https://digitaleconomy.stanford.edu/publication/canaries-in-the-coal-mine-six-facts-about-the-recent-employment-effects-of-artificial-intelligence/).* Stanford Digital Economy Lab, working paper (2025; revised August 2026).

Three design choices draw on this paper: routine-task share as the main driver of disruption risk (standing in for its AI-exposure measure), higher risk for junior workers, and automation pressure that rises over time. They reflect the paper's finding that employment in AI-exposed occupations has fallen behind for early-career workers (ages 22–25), with the gap widening over time. Consistent with this, routine-cognitive juniors made up the persistent tail of unemployed workers in the Tech-Driven scenario. Two differences: the paper finds the gap arises mainly from reduced hiring rather than layoffs, while this model has a fixed workforce with no new hires; and the paper's results are descriptive rather than causal.

## Notes

Generative AI (Claude Code, ChatGPT) assisted with design review and code generation; design decisions, testing, tuning and analysis are my own.

**Related projects from the same course:** [StockTrader](https://github.com/asligulcur/StockTrader_Signals_Strategies_2026) (competing LLM strategy agents) · [The AI Bidding War](https://github.com/asligulcur/The_AI_Bidding_War_April_2026) (governed multi-agent procurement negotiation).
