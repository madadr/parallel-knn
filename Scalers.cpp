#include "Scalers.hpp"

#include <cmath>
#include <iostream>
#include <mpi.h>

namespace
{
    using namespace std;
}

void Scalers::normalize(vector<double> &attributeSet)
{
    const auto [min, max] = findMinMax(attributeSet);

    double diff = max - min;

    for (auto& value : attributeSet)
    {
        value = (value - min) / diff;
    }
}

pair<double, double> Scalers::findMinMax(vector<double> &attributeSet)
{
    double min = attributeSet.at(0);
    double max = min;

    for (const auto& value : attributeSet)
    {
        if (value < min)
        {
            min = value;
        }
        
        if (value > max)
        {
            max = value;
        }
    }

    return std::make_pair(min, max);
}

void Scalers::standarize(vector<vector<double>>* attributeSet, int index)
{
    double averageVariation[2] {0.,};
    if (mpiWrapper.getWorldRank() == 0)
    {
        const auto [average, variation] = findAverageAndVariation(attributeSet->at(index));
        averageVariation[0] = average;
        averageVariation[1] = variation;
    }

    if (int errorCode = MPI_Bcast(averageVariation, 2, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        errorCode != MPI_SUCCESS)
    {
        cout << "Failed to broadcast data! Error:" << errorCode << ". Rank: " << mpiWrapper.getWorldRank() << endl;
    }

    // cout << mpiWrapper.getWorldRank() << ": " << averageVariation[0] << " + " << averageVariation[1] << endl;

    int valuesPerProcess = 999;
    if (mpiWrapper.getWorldRank() == 0)
    {
        valuesPerProcess = attributeSet->at(0).size() / mpiWrapper.getWorldSize();
    }
    if (int errorCode = MPI_Bcast(&valuesPerProcess, 1, MPI_INT, 0, MPI_COMM_WORLD);
        errorCode != MPI_SUCCESS)
    {
        cout << "Failed to broadcast data! Error:" << errorCode << ". Rank: " << mpiWrapper.getWorldRank() << endl;
    }
    // cout << "valuesPerProcess " << valuesPerProcess << endl;

    double* set;
    if (mpiWrapper.getWorldRank() == 0)
    {
        set = attributeSet->at(index).data();
    }
    vector<double> subset(valuesPerProcess);

    MPI_Scatter(set, valuesPerProcess, MPI_DOUBLE, subset.data(), valuesPerProcess, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    for (auto& value : subset)
    {
        value = (value - averageVariation[0]) / averageVariation[1];
    }

    MPI_Gather(subset.data(), valuesPerProcess, MPI_DOUBLE, set, valuesPerProcess, MPI_DOUBLE, 0, MPI_COMM_WORLD);
}

pair<double, double> Scalers::findAverageAndVariation(vector<double> &attributeSet)
{
    double average{};
    
    for (const auto& value : attributeSet)
    {
        average += value;
    }
    average /= attributeSet.size();

    double variation{};
    for (const auto& value : attributeSet)
    {
        auto tmp = value - average;
        variation += tmp * tmp;
    }
    variation /= attributeSet.size(); // variance
    variation = sqrt(variation);

    return std::make_pair(average, variation);
}
