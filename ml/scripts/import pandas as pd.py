import numpy as np
import matplotlib.pyplot as plt
from sklearn.svm import OneClassSVM

# dummy data
X = 0.3 * np.random.randn(100, 2)
X_train = np.r_[X + 2, X - 2]

clf = OneClassSVM(gamma='auto').fit(X_train)

xx, yy = np.meshgrid(np.linspace(-5, 5, 200), np.linspace(-5, 5, 200))
Z = clf.decision_function(np.c_[xx.ravel(), yy.ravel()])
Z = Z.reshape(xx.shape)

plt.contourf(xx, yy, Z, levels=50)
plt.scatter(X_train[:, 0], X_train[:, 1])
plt.title("OC-SVM Decision Boundary Example")

plt.savefig("ocsvm_boundary.png", dpi=300)
plt.show()