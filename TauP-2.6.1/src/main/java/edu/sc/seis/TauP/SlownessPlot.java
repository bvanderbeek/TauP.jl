/*
 * The TauP Toolkit: Flexible Seismic Travel-Time and Raypath Utilities.
 * Copyright (C) 1998-2000 University of South Carolina
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later
 * version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307, USA.
 * 
 * The current version can be found at <A
 * HREF="www.seis.sc.edu">http://www.seis.sc.edu</A>
 * 
 * Bug reports and comments should be directed to H. Philip Crotwell,
 * crotwell@seis.sc.edu or Tom Owens, owens@seis.sc.edu
 * 
 */
package edu.sc.seis.TauP;

import java.awt.Container;
import java.awt.Graphics;
import java.util.Vector;

/**
 * plots slowness versus depth.
 * 
 * @version 1.1.3 Wed Jul 18 15:00:35 GMT 2001
 * 
 * 
 * 
 * @author H. Philip Crotwell
 * 
 */
public class SlownessPlot extends XYPlot {

    public SlownessPlot(Container parent) {
        super(parent);
        title = "Slowness";
        xLabel = "p (sec/km or km-sec/km)";
        yLabel = "depth (km)";
        yTickWidth = 500;
    }

    public SlownessPlot(Container parent, int width, int height) {
        super(parent, width, height);
        title = "Slowness";
        xLabel = "p (sec/km or km-sec/km)";
        yLabel = "depth (km)";
        yTickWidth = 500;
    }

    public void plot(SlownessModel sModel, boolean isPWave) {
        SlownessLayer ss;
        xSegments = new Vector();
        ySegments = new Vector();
        xData = new double[2 * sModel.getNumLayers(isPWave)];
        yData = new double[2 * sModel.getNumLayers(isPWave)];
        if(!isPWave) {
            minX = 0.0;
            zoomMinX = minX;
            maxX = 2500.0;
            zoomMaxX = maxX;
            minY = 0.0;
            zoomMinY = minY;
            maxY = sModel.getRadiusOfEarth();
            zoomMaxY = maxY;
        } else {
            minX = 0.0;
            zoomMinX = minX;
            maxX = 1300.0;
            zoomMaxX = maxX;
            minY = 0.0;
            zoomMinY = minY;
            maxY = sModel.getRadiusOfEarth();
            zoomMaxY = maxY;
        }
        int j = 0;
        for(int i = 0; i < sModel.getNumLayers(isPWave); i++) {
            ss = sModel.getSlownessLayer(i, isPWave);
            yData[j] = sModel.getRadiusOfEarth() - ss.getTopDepth();
            xData[j] = ss.getTopP();
            if(DEBUG)
                System.out.println("x " + xData[j] + " y " + yData[j]);
            j++;
            yData[j] = sModel.getRadiusOfEarth() - ss.getBotDepth();
            xData[j] = ss.getBotP();
            if(DEBUG)
                System.out.println("x " + xData[j] + " y " + yData[j]);
            j++;
        }
        xSegments.addElement(xData);
        ySegments.addElement(yData);
        repaint();
    }

    public void paint(Graphics g) {
        super.paint(g);
    }
}
