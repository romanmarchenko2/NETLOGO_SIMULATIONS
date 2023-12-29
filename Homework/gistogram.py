import matplotlib.pyplot as plt

unemployment_rates = [0.0, 0.2, 0.4, 0.6, 0.8, 1]
number_of_prisoners = [454, 594, 657, 693, 712, 734]

plt.bar(unemployment_rates, number_of_prisoners, color='blue')
plt.xlabel('Unemployment Rate')
plt.ylabel('Number of Prisoners')
plt.title('Impact of Unemployment on Number of Prisoners')
plt.show()