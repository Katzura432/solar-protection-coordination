# Resume and interview material

## Suggested resume entry

**Protection Coordination with Distributed Solar — MATLAB / Simulink**

- Built a three-phase RMS feeder protection study with current-limited solar, directional phase/earth relays, voltage restraint, breaker feedback and transfer trip; achieved a 253 ms minimum grading margin across 7,200 design fault cases.
- Demonstrated selective fault clearance in 180/180 independent simulated validation cases versus 136/180 with conventional protection; verified 12/12 primary-breaker backup scenarios and eliminated nuisance trips in 15 tested no-fault profiles.

These are measured **simulation** outcomes. Use the entry after you can run the project, explain its equations and defend its limitations. Do not describe it as a field deployment or hardware-tested relay.

## Questions to prepare for

1. **Why can solar cause sympathetic tripping?** A remote inverter can send fault current upstream through a healthy section. A non-directional relay sees its magnitude without distinguishing the protected direction. It can also mistake normal reverse export for an overcurrent fault.
2. **Why does direction supervision alone not solve every problem?** It blocks reverse-current trips but does not restore a backup relay that never exceeds pickup or guarantee a sufficient time margin. The design sweep found one missing source-backup case and nine additional grading violations with the original settings.
3. **What does the 250 ms margin mean?** It is the prospective backup relay command time minus the primary breaker opening time. Breaker time is included separately from relay trip time. Comparing TCC curves at one shared current is insufficient because different relays can measure different fault currents.
4. **Why is inverter fault current different from generator fault current?** The inverter command is limited to 1.20 times its installed rated phase current in this model. It is not represented by a large synchronous-machine short-circuit contribution. The actual limit and control behavior depend on the equipment; 1.20 pu is a study assumption.
5. **What is the earth pickup measuring?** Residual current `Ia + Ib + Ic = 3I0`, in primary amps. If a relay is specified in I0 instead, the setting must be converted consistently.
6. **What is the purpose of R1 voltage restraint?** When terminal voltage falls, its effective phase-current pickup decreases, increasing source-backup sensitivity. The project uses a custom bounded quadratic characteristic and does not claim to emulate a commercial 51V relay.
7. **Why is fault clearance later than feeder-breaker opening?** Solar can still feed the isolated fault from the downstream side. In this study, direct transfer trip opens the PV intertie after its communication and breaker delays.
8. **How were settings selected?** From a forward load envelope and explicit pickup margins, then minimum-TMS grading on a radial hierarchy with fixed pickups and shared channel TMS. This is not global optimization of every possible protection scheme.
9. **What does the validation prove?** Correct behavior for the studied circuit family and scenarios. The 180 randomized cases were withheld from setting calculation. It does not establish performance for arbitrary topologies, inverter controls, real CT/VT signals or arcing faults.
10. **What would you improve before practical use?** Add equipment damage curves and maximum fault-duration requirements, vendor-specific inverter behavior, realistic relay polarization and measurement filters, CT saturation and VT-failure supervision. Some high-resistance faults are slow; the severe two-breaker-failure source backup takes about 31 seconds, so grading alone is insufficient for equipment protection.

## Explain one result in detail

Open `results/comparison_case.mat` and its two event logs. In the selected section-2 CA fault with 4 MW PV, conventional R3 trips on reverse current and opens the healthy downstream section before R2 isolates the faulted section. The coordinated scheme blocks that reverse trip and opens B2 while B3 stays closed.

Then show the default Simulink demonstration: an AG fault begins at 0.25 s, R3 trips, B3 opens after 50 ms, and solar contribution persists until the PV intertie opens after transfer trip. This makes the difference between **relay command**, **breaker opening**, and **complete fault clearance** visible.

## Portfolio evidence

- Single-line diagram and transparent network parameters.
- Relay settings with CT secondary equivalents.
- Phase and earth time-current curves.
- Full design sweep and separate validation results.
- Conventional/coordination comparison with event logs.
- Executed Simulink model and raw traces.
- Independent analytical fault-current checks and numerical verification.
- Engineering report that discusses slow-fault and model limitations.
