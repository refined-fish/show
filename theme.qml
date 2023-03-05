// Pegasus Frontend
// Copyright (C) 2017-2020  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.0
import SortFilterProxyModel 0.2
import "layer_filter"
import "layer_gameinfo"
import "layer_grid"
import "layer_platform"
import "configs.js" as CONFIGS
import "constants.js" as CONSTANTS
import "resources" as Resources

FocusScope {
	Resources.Music { id: music

	}
	
    SortFilterProxyModel {
        id: allFavorites
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "favorite"; value: true; }
		// sorters: RoleSorter { roleName: "collections"; sortOrder: Qt.DescendingOrder; }
		
    }
    SortFilterProxyModel {
        id: allLastPlayed
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "lastPlayed"; value: ""; inverted: true; }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }
    SortFilterProxyModel {
        id: filterLastPlayed
        sourceModel: allLastPlayed
        filters: IndexFilter { maximumIndex: {
            if (allLastPlayed.count >= 49) return 49
            return allLastPlayed.count
        } }
    }

    property var allCollections: {
       const collections = api.collections.toVarArray()
       collections.unshift({"name": "收藏", "shortName": "收藏游戏", "games": allFavorites})
       collections.unshift({"name": "最后", "shortName": "最近游戏", "games": filterLastPlayed})
       collections.unshift({"name": "全部", "shortName": "全部游戏", "games": api.allGames})
        return collections
    }
	

	
   Keys.onPressed: {
        //if (event.isAutoRepeat)
            //return;

        if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            topbar.prev();
			gamegrid.currentIndex = 0;
            return;
        }
        if (api.keys.isNextPage(event)) {
            event.accepted = true;
            topbar.next();
			gamegrid.currentIndex = 0;
            return;
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            gamepreview.focus = true;
            return;
        }
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            filter.focus = true;
            return;
        }
		// if (api.keys.isFilters(event) ) {//&& api.keys.isDetails(event)
            // event.accepted = true;
            // gamegrid.currentGame.favorite = !gamegrid.currentGame.favorite;
            // return;
        // }
    }

    PlatformBar {
        id: topbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 300

        model: allCollections // api.collections
        onCurrentIndexChanged: gamegrid.cells_need_recalc()
    }

    BackgroundImage {
        anchors.top: topbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        game: gamegrid.currentGame
    }

    GameGrid {
        id: gamegrid

        focus: true

        gridWidth: (parent.width * 0.6) - vpx(32)
        gridMarginTop: vpx(32)
        gridMarginRight: vpx(6)

        anchors.top: topbar.bottom
        anchors.bottom: parent.bottom
		anchors.bottomMargin: vpx(22)
        anchors.left: parent.left
        anchors.right: parent.right
		anchors.rightMargin: vpx(16)


        originalModel: topbar.currentCollection.games
        filteredModel: filteredGames
        onDetailsRequested: gamepreview.focus = true
        onLaunchRequested: launchGame()
    }

    GamePreview {
        id: gamepreview

        panelWidth: parent.width * 0.7 + vpx(72)
        anchors {
            top: topbar.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }

        game: gamegrid.currentGame
        onOpenRequested: gamepreview.focus = true
        onCloseRequested: gamegrid.focus = true
        onFiltersRequested: filter.focus = true
        onLaunchRequested: launchGame()
    }

    FilterLayer {
        id: filter
        anchors.fill: parent
        onCloseRequested: gamegrid.focus = true
    }
    SortFilterProxyModel {
        id: filteredGames
        sourceModel: topbar.currentCollection.games
        filters: [
            RegExpFilter {
                roleName: "title"
                pattern: filter.withTitle
                caseSensitivity: Qt.CaseInsensitive
                enabled: filter.withTitle
            },
                RangeFilter {
                roleName: "lastPlayed"
                minimumValue: 2
                enabled: filter.withLastPlayed
           },
            ValueFilter {
                roleName: "favorite"
                value: true
                enabled: filter.withFavorite
            }
        ]
		sorters: [
            RoleSorter { roleName: 'favorite'; sortOrder: Qt.DescendingOrder; enabled: topbar.currentIndex != 1}
        ]
    }

  Component.onCompleted: {
        const last_collection = api.memory.get('collection');

        if (!last_collection)
            return;

        const last_coll_idx = api
            .collections
            .toVarArray()
            .findIndex(c => c.name === last_collection);
			

	//	if (api.memory.get('collection')=="All Games"){   	
		if (api.memory.get('collection')=="全部"){			
			topbar.currentIndex = 0							
			//topbar.currentCollection = "All Games";
            // return;
		}
	//	if (api.memory.get('collection')=="Last Played"){  	
		if (api.memory.get('collection')=="最后"){			
			topbar.currentIndex = 1
			//topbar.currentCollection = "Last Played";
            return;
		}
		// if (api.memory.get('collection')=="Favorites"){		
		if (api.memory.get('collection')=="收藏"){			
			topbar.currentIndex = 2 						
			//topbar.currentCollection = "Favorites";
            // return;
		}
		if (last_coll_idx >= 0){
			topbar.currentIndex = last_coll_idx + 3;
		}
  
        const last_game = api.memory.get('game');
        if (!last_game)
            return;

        // const last_game_idx = api
            // .collections
            // .get(last_coll_idx)
            // .games
            // .toVarArray()
            // .findIndex(g => g.title === last_game);
        
		// if (last_game_idx < 0)
            // return;
		
        const last_index = api.memory.get('cuindex');
        if (!last_index)
            return;
        
        gamegrid.currentIndex = api.memory.get('cuindex');
	    gamegrid.positionViewAtIndex(api.memory.get('cuindex'));
	    gamegrid.memoryLoaded = true;

    }

    function launchGame() {
	
            api.memory.set('collection', topbar.currentCollection.name)
            api.memory.set('game', gamegrid.currentGame.title)
			api.memory.set('cuindex',gamegrid.currentIndex)

        let currentGame
        if(gamegrid.currentGame.launch) currentGame = gamegrid.currentGame
        else if (topbar.currentCollection.shortName === "收藏游戏")
            currentGame = api.allGames.get(allFavorites.mapToSource(gamegrid.currentIndex))
        else if (topbar.currentCollection.shortName === "最近游戏")
            currentGame = api.allGames.get(allLastPlayed.mapToSource(gamegrid.currentIndex))
//	else
//	currentGame = api.allGames.get(allGames.mapToSource(gamegrid.currentIndex))
        currentGame.launch();
    }

id: root
    FontLoader { id: subtitleFont; source: "../Resource/Fonts/Font.otf" 	}
}
