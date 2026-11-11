Temperatures, wildfire smoke and medication claims in Canada 🌡️🔥💊
================================================================================
    
This repository countains the codes and data to reproduce the analyses presented in *Effects of high temperature and wildfire smoke on prescription medication claims across Canada*.

- By [Jérémie Boudreault](https://jeremieboudreault.github.io/), Lea Mayer, Ghazaleh Allameh, Cirhan Truswell, Dale Perry, Scott Weichenthal and Jill Baumgartner
- Part of my postdoctoral researcher position at McGill University

---

### Data

We cannot share the claims data that was provided by a private insurer partner. However, we included temperature, PM2.5 and wildfire smoke data in the `data/sample.csv` file for 10 randomly selected FSAs across Canada. The `MEMBERS` column was set to 1000 for each FSA, and the number of claims was simulated with Poisson(λ=20) so that the codes can be ran.

---


### Script

The `main.R` script allows to run the models presented in the paper.


---

***Enjoy !***