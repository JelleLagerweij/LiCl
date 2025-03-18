# -*- coding: utf-8 -*-
"""
Created on Fri Apr 28 13:30:26 2023

@author: Jelle
"""

import scipy.constants as co
import scipy as sp
import numpy as np
import sys


def calculate_box_sizes(n_koh, n_w, t):
    # convert to kelving
    t += co.zero_Celsius
    m = n_koh*55/n_w
    
    # Set basic masses
    u_H2O = 2*1.00797 + 1*15.9994  # mass H2O
    u_KOH = 1*1.00797 + 1*15.9994 + 1*39.0983  # mass of KOH

    # Density equation from Gilliam et al (2007)
    # Datapoints from Gilliam et al converted to Kelvin
    T = np.arange(0, 71, 5, dtype=float) + co.zero_Celsius   # Table 3
    A = np.array([1001.9, 1001.0, 1000.0, 999.06, 998.15,
                  997.03, 995.75, 994.05, 992.07, 990.16,
                  988.45, 985.66, 983.20, 980.66, 977.88])  # Table 3
    spline = sp.interpolate.CubicSpline(T, A)
    a = spline(t)  # retrieve constant at temperature intended
    
    w = m*u_KOH/(55*u_H2O + m*u_KOH)
    rho = a*np.exp(0.0086*100*w)
    m = (n_w*u_H2O + n_koh*u_KOH)/(1000*co.N_A)  # check the molality

    L = 1e10*np.power(m/rho, 1/3)  # (mass/density)^(1/3)
    r = (n_w + n_koh)*rho/(m*co.N_A*1e3)
    return r, L, t, rho

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 boxsizes.py <n_koh> <n_w> <T>")
        sys.exit(1)

    n_koh = int(sys.argv[1])
    n_w = int(sys.argv[2])
    T = float(sys.argv[3])

    r, L, t, rho = calculate_box_sizes(n_koh, n_w, T)
    print(r)
    print(L)
    print(t)
    # print(rho)
