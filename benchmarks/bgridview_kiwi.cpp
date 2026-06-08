// 2x6 UI grid layout benchmark for upstream Kiwi.
//
// Run with:
//   c++ -O3 -DNDEBUG -std=c++17 -Ideps/kiwi benchmarks/bgridview_kiwi.cpp -o /tmp/bgridview_kiwi
//   KIWIBERRY_BENCH_ITERS=20000 /tmp/bgridview_kiwi

#include <kiwi/kiwi.h>

#include <array>
#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

namespace
{

constexpr int RowCount = 2;
constexpr int ColCount = 6;
constexpr int CellCount = RowCount * ColCount;

using Clock = std::chrono::steady_clock;

int benchIterations(int defaultValue)
{
    const char* raw = std::getenv("KIWIBERRY_BENCH_ITERS");
    if (!raw || raw[0] == '\0')
        return defaultValue;
    return std::stoi(raw);
}

std::string variableName(const char* prefix, int index, const char* suffix)
{
    std::ostringstream stream;
    stream << prefix << index << suffix;
    return stream.str();
}

int cellIndex(int row, int col)
{
    return row * ColCount + col;
}

struct GridVars
{
    kiwi::Variable containerLeft { "containerLeft" };
    kiwi::Variable containerTop { "containerTop" };
    kiwi::Variable containerWidth { "containerWidth" };
    kiwi::Variable containerHeight { "containerHeight" };
    std::array<kiwi::Variable, ColCount> colLeft;
    std::array<kiwi::Variable, ColCount> colWidth;
    std::array<kiwi::Variable, ColCount> colRight;
    std::array<kiwi::Variable, RowCount> rowTop;
    std::array<kiwi::Variable, RowCount> rowHeight;
    std::array<kiwi::Variable, RowCount> rowBottom;
    std::array<kiwi::Variable, CellCount> cellLeft;
    std::array<kiwi::Variable, CellCount> cellTop;
    std::array<kiwi::Variable, CellCount> cellWidth;
    std::array<kiwi::Variable, CellCount> cellHeight;

    GridVars()
    {
        for (int col = 0; col < ColCount; ++col)
        {
            colLeft[col].setName(variableName("col", col, "Left"));
            colWidth[col].setName(variableName("col", col, "Width"));
            colRight[col].setName(variableName("col", col, "Right"));
        }

        for (int row = 0; row < RowCount; ++row)
        {
            rowTop[row].setName(variableName("row", row, "Top"));
            rowHeight[row].setName(variableName("row", row, "Height"));
            rowBottom[row].setName(variableName("row", row, "Bottom"));
        }

        for (int cell = 0; cell < CellCount; ++cell)
        {
            cellLeft[cell].setName(variableName("cell", cell, "Left"));
            cellTop[cell].setName(variableName("cell", cell, "Top"));
            cellWidth[cell].setName(variableName("cell", cell, "Width"));
            cellHeight[cell].setName(variableName("cell", cell, "Height"));
        }
    }
};

struct GridBench
{
    kiwi::Solver solver;
    GridVars vars;

    GridBench()
    {
        addGridConstraints();
    }

    void addGridConstraints()
    {
        constexpr double gutter = 8.0;
        constexpr double padding = 12.0;
        constexpr double cellInset = 4.0;
        constexpr double minColWidth = 64.0;
        constexpr double minRowHeight = 44.0;

        solver.addEditVariable(vars.containerWidth, kiwi::strength::strong);
        solver.addEditVariable(vars.containerHeight, kiwi::strength::strong);
        solver.addConstraint(vars.containerLeft == 0.0);
        solver.addConstraint(vars.containerTop == 0.0);

        for (int col = 0; col < ColCount; ++col)
        {
            solver.addConstraint(
                vars.colRight[col] == vars.colLeft[col] + vars.colWidth[col]
            );
            solver.addConstraint(vars.colWidth[col] >= minColWidth);
            solver.addConstraint(
                (vars.colWidth[col] == 110.0 + col * 3.0) | kiwi::strength::weak
            );
            if (col == 0)
            {
                solver.addConstraint(
                    vars.colLeft[col] == vars.containerLeft + padding
                );
            }
            else
            {
                solver.addConstraint(
                    vars.colLeft[col] == vars.colRight[col - 1] + gutter
                );
                solver.addConstraint(
                    (vars.colWidth[col] == vars.colWidth[0]) | kiwi::strength::medium
                );
            }
        }

        solver.addConstraint(
            vars.colRight[ColCount - 1] ==
                vars.containerLeft + vars.containerWidth - padding
        );

        for (int row = 0; row < RowCount; ++row)
        {
            solver.addConstraint(
                vars.rowBottom[row] == vars.rowTop[row] + vars.rowHeight[row]
            );
            solver.addConstraint(vars.rowHeight[row] >= minRowHeight);
            solver.addConstraint(
                (vars.rowHeight[row] == 96.0 + row * 12.0) | kiwi::strength::weak
            );
            if (row == 0)
            {
                solver.addConstraint(vars.rowTop[row] == vars.containerTop + padding);
            }
            else
            {
                solver.addConstraint(
                    vars.rowTop[row] == vars.rowBottom[row - 1] + gutter
                );
                solver.addConstraint(
                    (vars.rowHeight[row] == vars.rowHeight[0]) |
                    kiwi::strength::medium
                );
            }
        }

        solver.addConstraint(
            vars.rowBottom[RowCount - 1] ==
                vars.containerTop + vars.containerHeight - padding
        );

        for (int row = 0; row < RowCount; ++row)
        {
            for (int col = 0; col < ColCount; ++col)
            {
                const int index = cellIndex(row, col);
                solver.addConstraint(
                    vars.cellLeft[index] == vars.colLeft[col] + cellInset
                );
                solver.addConstraint(
                    vars.cellTop[index] == vars.rowTop[row] + cellInset
                );
                solver.addConstraint(
                    vars.cellWidth[index] == vars.colWidth[col] - 2.0 * cellInset
                );
                solver.addConstraint(
                    vars.cellHeight[index] == vars.rowHeight[row] - 2.0 * cellInset
                );
                solver.addConstraint(vars.cellWidth[index] >= 24.0);
                solver.addConstraint(vars.cellHeight[index] >= 20.0);
            }
        }
    }

    void updateLayout(int iteration)
    {
        solver.suggestValue(vars.containerWidth, 760.0 + iteration % 37);
        solver.suggestValue(vars.containerHeight, 260.0 + iteration % 23);
        solver.updateVariables();
    }

    double checksum() const
    {
        double result = 0.0;
        for (int cell = 0; cell < CellCount; ++cell)
        {
            result += vars.cellLeft[cell].value();
            result += vars.cellTop[cell].value();
            result += vars.cellWidth[cell].value();
            result += vars.cellHeight[cell].value();
        }
        return result;
    }
};

double finishTiming(
    const char* name, int iterations, Clock::time_point started, double sum
)
{
    const auto elapsed = std::chrono::duration<double, std::milli>(
        Clock::now() - started
    ).count();
    std::cout << std::fixed << std::setprecision(3) << name << ": " << elapsed
              << " ms total, " << std::setprecision(6)
              << elapsed / static_cast<double>(iterations)
              << " ms/iter, checksum=" << std::setprecision(3) << sum << '\n';
    return elapsed;
}

} // namespace

int main()
{
#ifdef NDEBUG
    const int iterations = benchIterations(20000);
#else
    const int iterations = benchIterations(50);
#endif

    std::cout << "implementation=kiwi-cpp grid=" << RowCount << "x" << ColCount
              << " iterations=" << iterations << '\n';

    auto started = Clock::now();
    double sum = 0.0;
    for (int i = 0; i < iterations; ++i)
    {
        GridBench bench;
        bench.updateLayout(i);
        sum += bench.checksum();
    }
    finishTiming("build+solve", iterations, started, sum);

    GridBench bench;
    started = Clock::now();
    sum = 0.0;
    for (int i = 0; i < iterations * 20; ++i)
    {
        bench.updateLayout(i);
        sum += bench.checksum();
    }
    finishTiming("edit+update", iterations * 20, started, sum);

    return 0;
}
