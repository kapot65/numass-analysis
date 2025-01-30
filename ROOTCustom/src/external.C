/**
 * @file external.C
 *
 * @brief File contains some wrapping functions i missed in ROOT.jl
 */
#include "TVirtualPad.h"
#include <iostream>
#include <TH1D.h>
#include <TCanvas.h>
#include <TROOT.h>
#include <TStyle.h>
#include <TIterator.h>

using namespace std;

// Find ROOT object by name in the list of canvases
template<typename T>
T* FindByName(const char* name) {
    auto obj = gROOT->FindObject(name);
    if (obj != nullptr) {
      return dynamic_cast<T*>(obj);
    }
    return nullptr;
}

void DivideCanvas(const char* name, int nx, int ny) {
    TCanvas* c = FindByName<TCanvas>(name);
    if (c) {
        c->Divide(nx, ny);  // Divide the canvas into a grid of nx by ny pads
    } else {
        std::cout << "Canvas not found!" << std::endl;
    }
}

void adjustHistStyle(const char* name) {
  TH1D* hist = FindByName<TH1D>(name);
  if (hist) {
    hist->SetLineWidth(2);     // Set line width to 2
  } else {
    std::cout << "Histogram not found!" << std::endl;
  }
}

void updateGraphScales() {
  
  gPad->ResizePad();
  gPad->Modified();
  gPad->Update();
}

void external() {
  gStyle->SetOptFit(1111);
  cout << "External functions loaded" << endl;
}