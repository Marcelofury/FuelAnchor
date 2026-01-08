/**
 * Credit Score Screen
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../hooks/useTheme';
import { creditAPI } from '../services/api';

interface ScoreFactor {
  score: number;
  description: string;
  tip: string;
}

interface CreditData {
  score: number;
  tier: string;
  daysUntilScorable: number;
  factors: {
    age: ScoreFactor;
    frequency: ScoreFactor;
    consistency: ScoreFactor;
    volume: ScoreFactor;
    diversity: ScoreFactor;
  } | null;
  eligibleForCredit: boolean;
  recommendedLimit: number;
  benefits: string[];
}

export default function CreditScreen() {
  const { theme } = useTheme();
  const [creditData, setCreditData] = useState<CreditData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadCreditData();
  }, []);

  const loadCreditData = async () => {
    try {
      const [scoreRes, factorsRes, eligibilityRes] = await Promise.all([
        creditAPI.getScore(),
        creditAPI.getFactors(),
        creditAPI.getEligibility(),
      ]);

      setCreditData({
        score: scoreRes.data.data.score,
        tier: scoreRes.data.data.tier,
        daysUntilScorable: scoreRes.data.data.daysUntilScorable || 0,
        factors: factorsRes.data.data.factors,
        eligibleForCredit: eligibilityRes.data.data.isEligible,
        recommendedLimit: eligibilityRes.data.data.recommendedLimit || 0,
        benefits: eligibilityRes.data.data.benefits || [],
      });
    } catch (error) {
      console.error('Failed to load credit data:', error);
      // Set default data for demo
      setCreditData({
        score: 0,
        tier: 'UNSCORED',
        daysUntilScorable: 90,
        factors: null,
        eligibleForCredit: false,
        recommendedLimit: 0,
        benefits: [],
      });
    } finally {
      setIsLoading(false);
    }
  };

  const getTierColor = (tier: string) => {
    switch (tier) {
      case 'PLATINUM': return '#9CA3AF';
      case 'GOLD': return '#F59E0B';
      case 'SILVER': return '#6B7280';
      case 'BRONZE': return '#B45309';
      default: return theme.colors.textSecondary;
    }
  };

  const getScoreGradient = (score: number) => {
    if (score >= 750) return theme.colors.success;
    if (score >= 650) return '#F59E0B';
    if (score >= 500) return theme.colors.info;
    if (score > 0) return theme.colors.warning;
    return theme.colors.textSecondary;
  };

  const styles = createStyles(theme);

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Score Card */}
      <View style={styles.scoreCard}>
        <Text style={styles.scoreLabel}>Fuel Credit Score</Text>
        <View style={styles.scoreContainer}>
          <Text style={[styles.scoreNumber, { color: getScoreGradient(creditData?.score || 0) }]}>
            {creditData?.score || '---'}
          </Text>
          <View style={[styles.tierBadge, { backgroundColor: getTierColor(creditData?.tier || '') }]}>
            <Text style={styles.tierText}>{creditData?.tier}</Text>
          </View>
        </View>
        <View style={styles.scoreRange}>
          <Text style={styles.scoreRangeText}>300</Text>
          <View style={styles.scoreBar}>
            <View 
              style={[
                styles.scoreProgress, 
                { 
                  width: `${((creditData?.score || 300) - 300) / 5.5}%`,
                  backgroundColor: getScoreGradient(creditData?.score || 0)
                }
              ]} 
            />
          </View>
          <Text style={styles.scoreRangeText}>850</Text>
        </View>
      </View>

      {/* Eligibility Status */}
      <View style={styles.eligibilityCard}>
        <View style={styles.eligibilityHeader}>
          <Ionicons 
            name={creditData?.eligibleForCredit ? 'checkmark-circle' : 'time'} 
            size={24} 
            color={creditData?.eligibleForCredit ? theme.colors.success : theme.colors.warning} 
          />
          <Text style={styles.eligibilityTitle}>
            {creditData?.eligibleForCredit ? 'Eligible for Credit!' : 'Building Credit History'}
          </Text>
        </View>
        {creditData?.eligibleForCredit ? (
          <View>
            <Text style={styles.eligibilityText}>
              Recommended credit limit: <Text style={styles.highlightText}>KES {creditData.recommendedLimit.toLocaleString()}</Text>
            </Text>
          </View>
        ) : (
          <Text style={styles.eligibilityText}>
            {creditData?.daysUntilScorable} days of activity needed to unlock credit products.
          </Text>
        )}
      </View>

      {/* Score Factors */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Score Factors</Text>
        {creditData?.factors ? (
          Object.entries(creditData.factors).map(([key, factor]) => (
            <View key={key} style={styles.factorCard}>
              <View style={styles.factorHeader}>
                <Text style={styles.factorName}>{key.charAt(0).toUpperCase() + key.slice(1)}</Text>
                <Text style={styles.factorScore}>{factor.score}/100</Text>
              </View>
              <View style={styles.factorBar}>
                <View 
                  style={[
                    styles.factorProgress, 
                    { 
                      width: `${factor.score}%`,
                      backgroundColor: factor.score >= 80 ? theme.colors.success : 
                                       factor.score >= 50 ? theme.colors.warning : 
                                       theme.colors.error
                    }
                  ]} 
                />
              </View>
              <Text style={styles.factorTip}>{factor.tip}</Text>
            </View>
          ))
        ) : (
          <View style={styles.noDataCard}>
            <Ionicons name="bar-chart-outline" size={48} color={theme.colors.textSecondary} />
            <Text style={styles.noDataText}>
              Start making fuel purchases to build your credit profile
            </Text>
          </View>
        )}
      </View>

      {/* Benefits */}
      {creditData?.benefits && creditData.benefits.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Your Benefits</Text>
          {creditData.benefits.map((benefit, index) => (
            <View key={index} style={styles.benefitItem}>
              <Ionicons name="checkmark-circle" size={20} color={theme.colors.success} />
              <Text style={styles.benefitText}>{benefit}</Text>
            </View>
          ))}
        </View>
      )}

      {/* How It Works */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>How Credit Scoring Works</Text>
        <View style={styles.howItWorksCard}>
          <View style={styles.howItWorksStep}>
            <View style={styles.stepNumber}><Text style={styles.stepNumberText}>1</Text></View>
            <Text style={styles.stepText}>Make consistent fuel purchases with FuelAnchor</Text>
          </View>
          <View style={styles.howItWorksStep}>
            <View style={styles.stepNumber}><Text style={styles.stepNumberText}>2</Text></View>
            <Text style={styles.stepText}>After 90 days, receive your initial credit score</Text>
          </View>
          <View style={styles.howItWorksStep}>
            <View style={styles.stepNumber}><Text style={styles.stepNumberText}>3</Text></View>
            <Text style={styles.stepText}>Unlock micro-loans, discounts & insurance products</Text>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}

const createStyles = (theme: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  content: {
    padding: theme.spacing.md,
    paddingTop: 60,
    paddingBottom: theme.spacing.xxl,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.background,
  },
  scoreCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.xl,
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  scoreLabel: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.md,
  },
  scoreContainer: {
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  scoreNumber: {
    fontSize: 72,
    fontWeight: 'bold',
  },
  tierBadge: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.sm,
  },
  tierText: {
    color: '#fff',
    fontSize: theme.fontSize.sm,
    fontWeight: '600',
  },
  scoreRange: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    gap: theme.spacing.sm,
  },
  scoreRangeText: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.textSecondary,
  },
  scoreBar: {
    flex: 1,
    height: 8,
    backgroundColor: theme.colors.border,
    borderRadius: 4,
    overflow: 'hidden',
  },
  scoreProgress: {
    height: '100%',
    borderRadius: 4,
  },
  eligibilityCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.lg,
  },
  eligibilityHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
  },
  eligibilityTitle: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.text,
  },
  eligibilityText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  highlightText: {
    color: theme.colors.success,
    fontWeight: '600',
  },
  section: {
    marginBottom: theme.spacing.lg,
  },
  sectionTitle: {
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: theme.spacing.md,
  },
  factorCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  factorHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  factorName: {
    fontSize: theme.fontSize.md,
    fontWeight: '500',
    color: theme.colors.text,
  },
  factorScore: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.primary,
  },
  factorBar: {
    height: 6,
    backgroundColor: theme.colors.border,
    borderRadius: 3,
    marginBottom: theme.spacing.sm,
    overflow: 'hidden',
  },
  factorProgress: {
    height: '100%',
    borderRadius: 3,
  },
  factorTip: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  noDataCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  noDataText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    marginTop: theme.spacing.md,
  },
  benefitItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  benefitText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
  },
  howItWorksCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
  },
  howItWorksStep: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  stepNumber: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: theme.colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepNumberText: {
    color: '#fff',
    fontWeight: '600',
  },
  stepText: {
    flex: 1,
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
  },
});
